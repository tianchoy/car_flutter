import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import '../../models/message/msg_model.dart';
import '../../models/api_response.dart';
import '../../services/push/push_service.dart';
import '../../utils/logger.dart';
import 'message_detail_dialog.dart';
import 'messages_repository.dart';

class MessagesController extends GetxController {
  MessagesController({MessagesRepository? repository})
    : _repository = repository ?? MessagesRepository();

  final MessagesRepository _repository;
  final messages = <MessageModel>[].obs;
  final scrollController = ScrollController();
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isCheckingNewMessages = false.obs;
  final unreadCount = 0.obs;
  final totalCount = 0.obs;
  final pageSize = 10.obs;
  final totalPage = 1.obs;
  final currPage = 1.obs;
  // 轮询到的新消息：先缓存起来，由用户点击「有 N 条新消息」后再插入列表，
  // 避免自动刷新导致列表跳动（参考 carConnectInternet 消息页逻辑）。
  final newMessageCount = 0.obs;
  final List<MessageModel> _pendingNewMessages = <MessageModel>[];
  Timer? _newMessageTimer;
  bool _isClosed = false;

  @override
  void onInit() {
    super.onInit();
    PushService.to.addEventListener(_onPushEvent);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (await checkLoginStatus()) {
      await refreshMessages();
      _startNewMessageCheck();
      // 进入消息页时消费推送带来的待处理消息（冷启动点击通知的场景）。
      await openPendingPushMessage();
    }
  }

  void _onPushEvent(PushEventKind kind, String messageId) {
    // 推送已在 PushService 中落盘，此处只负责刷新列表并打开对应详情。
    unawaited(openPendingPushMessage());
  }

  Future<bool> checkLoginStatus() async {
    final token = await _repository.getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> loadMessages({bool append = false}) async {
    if (_isClosed || isLoading.value || isLoadingMore.value) return;
    if (append) {
      if (currPage.value >= totalPage.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    final requestedPage = append ? currPage.value + 1 : 1;
    try {
      final response = await _repository.fetchMessages(
        page: requestedPage,
        pageSize: pageSize.value,
      );
      if (_isClosed) return;
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isTokenExpired) {
        Log.w('消息接口登录已过期');
        return;
      }
      if (!result.isSuccess) {
        Log.w('加载消息失败: ${result.message}');
        return;
      }

      final data = result.data ?? const <String, dynamic>{};
      final rawList = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      final loaded = rawList
          .whereType<Map>()
          .map((item) => MessageModel.fromJson(jsonMapFrom(item)))
          .toList();

      totalCount.value = intValue(data['totalCount'] ?? data['total']);
      pageSize.value = intValue(data['pageSize'], fallback: pageSize.value);
      totalPage.value = intValue(
        data['totalPage'],
        fallback: totalCount.value == 0
            ? 1
            : ((totalCount.value + pageSize.value - 1) ~/ pageSize.value),
      );
      currPage.value = requestedPage;
      if (append) {
        messages.addAll(loaded);
      } else {
        messages.assignAll(loaded);
      }
      await _loadUnreadCount();
    } catch (error, stackTrace) {
      if (!_isClosed) {
        Log.e('加载消息失败', error: error, stackTrace: stackTrace);
        AppToast.show('错误', '加载消息失败，请稍后重试');
      }
    } finally {
      if (!_isClosed) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> refreshMessages() async {
    currPage.value = 1;
    // 参考项目：初始化（下拉刷新）时清空暂存的新消息。
    _pendingNewMessages.clear();
    newMessageCount.value = 0;
    await loadMessages();
  }

  Future<void> loadMoreMessages() => loadMessages(append: true);

  Future<void> markAsRead(MessageModel message) async {
    if (message.messageId.isEmpty || message.status != 1) return;
    try {
      final response = await _repository.markMessageRead(message.messageId);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) await refreshMessages();
    } catch (error, stackTrace) {
      Log.w('标记消息已读失败: $error');
      Log.d(stackTrace);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _repository.fetchUnreadCount();
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) unreadCount.value = intValue(result.data);
    } catch (_) {
      // The list remains usable when the optional badge request fails.
    }
  }

  /// 启动定时检查新消息（对齐参考项目：10 秒一次）。
  void _startNewMessageCheck() {
    _newMessageTimer?.cancel();
    _newMessageTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkNewMessages(),
    );
  }

  DateTime? _parseTime(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  /// 拉取第一页，筛出「比已加载的最新一条还新且未重复」的消息。
  Future<List<MessageModel>> _findLatestMessages() async {
    if (_isClosed ||
        isLoading.value ||
        isLoadingMore.value ||
        isCheckingNewMessages.value) {
      return const <MessageModel>[];
    }
    isCheckingNewMessages.value = true;
    try {
      final response = await _repository.fetchMessages(
        page: 1,
        pageSize: pageSize.value,
      );
      if (_isClosed) return const <MessageModel>[];
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) return const <MessageModel>[];
      final data = result.data ?? const <String, dynamic>{};
      final rawList = data['list'] is List
          ? data['list'] as List
          : data['rows'] is List
          ? data['rows'] as List
          : const <dynamic>[];
      final latest = rawList
          .whereType<Map>()
          .map((item) => MessageModel.fromJson(jsonMapFrom(item)))
          .toList();

      final existingIds = <String>{};
      DateTime? latestLoadedTime;
      void remember(MessageModel message) {
        if (message.messageId.isNotEmpty) {
          existingIds.add(message.messageId);
        }
        final time = _parseTime(message.createTime);
        if (time != null &&
            (latestLoadedTime == null || time.isAfter(latestLoadedTime!))) {
          latestLoadedTime = time;
        }
      }
      messages.forEach(remember);
      _pendingNewMessages.forEach(remember);

      final found = <MessageModel>[];
      for (final message in latest) {
        final id = message.messageId;
        final time = _parseTime(message.createTime);
        final isNewerThanLoaded = latestLoadedTime == null
            ? messages.isEmpty && _pendingNewMessages.isEmpty
            : (time != null && time.isAfter(latestLoadedTime!));
        if (id.isNotEmpty && !existingIds.contains(id) && isNewerThanLoaded) {
          existingIds.add(id);
          found.add(message);
        }
      }
      return found;
    } catch (error, stackTrace) {
      Log.d('检查新消息失败: $error');
      Log.d(stackTrace);
      return const <MessageModel>[];
    } finally {
      if (!_isClosed) isCheckingNewMessages.value = false;
    }
  }

  /// 消费推送带来的待处理消息：先刷新列表，再在第一页定位同一 `messageId`
  /// 并自动打开详情（对齐源工程 `openPendingPushMessage`）。
  Future<void> openPendingPushMessage({int attempt = 0}) async {
    if (_isClosed) return;
    if (isLoading.value || isLoadingMore.value || isCheckingNewMessages.value) {
      if (attempt >= 20) return;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return openPendingPushMessage(attempt: attempt + 1);
    }
    final messageId = await PushService.to.consumePendingMessageId();
    final shouldRefresh = await PushService.to.consumeStaleFlag();
    if (messageId.isEmpty && !shouldRefresh) return;
    await refreshMessages();
    if (_isClosed || messageId.isEmpty) return;
    final target = _findById(messageId);
    if (target == null) return;
    await markAsRead(target);
    if (_isClosed) return;
    await MessageDetailDialog.show(target);
  }

  MessageModel? _findById(String messageId) {
    for (final message in messages) {
      if (message.messageId == messageId) return message;
    }
    return null;
  }

  /// 定时检查：只暂存新消息，避免打断用户当前的阅读位置。
  Future<void> checkNewMessages() async {
    final latest = await _findLatestMessages();
    if (_isClosed || latest.isEmpty) return;
    _pendingNewMessages.addAll(latest);
    newMessageCount.value = _pendingNewMessages.length;
    await _loadUnreadCount();
  }

  /// 用户点击「有 N 条新消息」：先补查一次，再把暂存消息一次性插入列表顶部并回到顶部。
  Future<void> loadNewMessages() async {
    if (isLoading.value || isLoadingMore.value) return;
    await checkNewMessages();
    if (_isClosed || _pendingNewMessages.isEmpty) return;
    messages.insertAll(0, _pendingNewMessages);
    _pendingNewMessages.clear();
    newMessageCount.value = 0;
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void onClose() {
    _isClosed = true;
    PushService.to.removeEventListener(_onPushEvent);
    _newMessageTimer?.cancel();
    scrollController.dispose();
    messages.clear();
    super.onClose();
  }
}
