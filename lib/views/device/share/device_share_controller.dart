import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/widgets/app_toast.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'package:car/models/home/device_model.dart';
import 'package:car/models/api_response.dart';
import 'package:car/widgets/reference_date_time_picker.dart';
import 'device_share_repository.dart';

class DeviceShareController extends GetxController {
  DeviceShareController({DeviceShareRepository? repository})
    : _repository = repository ?? DeviceShareRepository();

  final DeviceShareRepository _repository;
  final DeviceModel? device = DeviceRouteArgs.deviceFrom(Get.arguments);
  final enabled = false.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final isLoadingMore = false.obs;
  final shares = <JsonMap>[].obs;
  final sharees = <JsonMap>[].obs;
  final errorMessage = ''.obs;
  final page = 1.obs;
  final totalCount = 0.obs;
  final totalPage = 1.obs;
  final targetPhoneController = TextEditingController();
  final expireDate = Rxn<DateTime>();

  String get deviceId => device?.deviceId ?? '';
  String get deviceName => device?.deviceName?.isNotEmpty == true
      ? device!.deviceName!
      : device?.deviceNo ?? deviceId;
  bool get hasMore => page.value < totalPage.value;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    if (deviceId.isEmpty) {
      isLoading.value = false;
      errorMessage.value = '设备信息不存在';
      return;
    }
    try {
      final response = await _repository.fetchEnabled();
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isSuccess) {
        final data = result.data ?? const <String, dynamic>{};
        enabled.value = _boolValue(data['enabled']);
      } else {
        errorMessage.value = result.message.isEmpty
            ? '获取分享开关失败'
            : result.message;
      }
      if (enabled.value) await loadShares(reset: true);
    } catch (_) {
      errorMessage.value = '加载分享功能失败，请稍后重试';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> loadShares({bool reset = false}) async {
    if (deviceId.isEmpty || isLoadingMore.value) return;
    if (!reset && !hasMore) return;
    final requestedPage = reset ? 1 : page.value;
    isLoadingMore.value = true;
    try {
      final response = await _repository.fetchShares(
        deviceId,
        <String, dynamic>{'pageNum': requestedPage, 'pageSize': 10},
      );
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (!result.isSuccess) {
        errorMessage.value = result.message.isEmpty
            ? '获取分享列表失败'
            : result.message;
        return;
      }
      final data = result.data ?? const <String, dynamic>{};
      final rawList = data['list'] is List
          ? data['list'] as List
          : const <dynamic>[];
      final loaded = rawList.whereType<Map>().map(jsonMapFrom).toList();
      if (reset) {
        shares.assignAll(loaded);
      } else {
        shares.addAll(loaded);
      }
      totalCount.value = intValue(data['totalCount']);
      totalPage.value = intValue(data['totalPage'], fallback: 1);
      page.value = requestedPage + 1;
    } catch (_) {
      errorMessage.value = '获取分享列表失败，请稍后重试';
    } finally {
      if (!isClosed) isLoadingMore.value = false;
    }
  }

  Future<void> pickExpireDate(BuildContext context) async {
    final selected = await showReferenceDateTimePicker(
      context: context,
      initialDate: expireDate.value ?? DateTime.now(),
      allowFuture: true,
    );
    if (selected != null) expireDate.value = selected;
  }

  Future<bool> createShare() async {
    final phone = targetPhoneController.text.trim();
    if (deviceId.isEmpty) {
      AppToast.show('提示', '设备ID不能为空');
      return false;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      AppToast.show('提示', '请输入正确的手机号');
      return false;
    }
    isSubmitting.value = true;
    try {
      final expire = expireDate.value;
      final response = await _repository.createShare(<String, dynamic>{
        'deviceId': deviceId,
        'targetPhone': phone,
        'role': 'view',
        if (expire != null)
          'expireTime':
              DateTime(
                expire.year,
                expire.month,
                expire.day,
                23,
                59,
                59,
              ).millisecondsSinceEpoch ~/
              1000,
      });
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (!result.isSuccess) {
        AppToast.show('提示', result.message.isEmpty ? '分享失败' : result.message);
        return false;
      }
      targetPhoneController.clear();
      expireDate.value = null;
      AppToast.show('成功', '设备分享成功');
      await loadShares(reset: true);
      return true;
    } catch (_) {
      AppToast.show('提示', '分享失败，请稍后重试');
      return false;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  Future<void> revokeShare(JsonMap share) async {
    final shareId = stringValue(share['shareId'] ?? share['id']);
    if (shareId.isEmpty) return;
    final confirmed = await Get.dialog<bool>(
      CupertinoAlertDialog(
        title: const Text('撤销分享'),
        content: Text('确定撤销“$deviceName”的分享吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Get.back(result: true),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await _repository.revokeShare(shareId);
      final result = ApiResponse<Object?>.fromJson(response.data);
      if (result.isSuccess) {
        AppToast.show('成功', '分享已撤销');
        await loadShares(reset: true);
      } else {
        AppToast.show('提示', result.message.isEmpty ? '撤销失败' : result.message);
      }
    } catch (_) {
      AppToast.show('提示', '撤销失败，请稍后重试');
    }
  }

  Future<void> showSharees(JsonMap share) async {
    sharees.clear();
    final id = stringValue(share['deviceId'] ?? deviceId);
    try {
      final response = await _repository.fetchShares(id, <String, dynamic>{
        'pageNum': 1,
        'pageSize': 50,
      });
      final result = ApiResponse<JsonMap>.fromJson(
        response.data,
        dataParser: jsonMapFrom,
      );
      if (result.isSuccess) {
        final raw = result.data?['list'];
        if (raw is List) {
          sharees.assignAll(raw.whereType<Map>().map(jsonMapFrom));
        }
      } else {
        AppToast.show(
          '提示',
          result.message.isEmpty ? '获取被分享者失败' : result.message,
        );
      }
    } catch (_) {
      AppToast.show('提示', '获取被分享者失败，请稍后重试');
    }
    if (Get.context != null) {
      await Get.dialog<void>(_ShareesDialog(items: sharees));
    }
  }

  String shareStatus(JsonMap share) {
    switch (stringValue(share['status'])) {
      case 'active':
        return '生效中';
      case 'revoked':
        return '已撤销';
      case 'expired':
        return '已过期';
      case 'exited':
        return '已退出';
      default:
        return stringValue(share['status'], fallback: '未知状态');
    }
  }

  String sharePerson(JsonMap share) => stringValue(
    share['targetNickName'] ?? share['targetPhoneMasked'],
    fallback: '--',
  );

  String formatTime(Object? value) {
    final number = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    if (number <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(
      number < 100000000000 ? number * 1000 : number,
    );
    String pad(int item) => item.toString().padLeft(2, '0');
    return '${date.year}-${pad(date.month)}-${pad(date.day)} ${pad(date.hour)}:${pad(date.minute)}';
  }

  bool _boolValue(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString().toLowerCase() == 'true' || value.toString() == '1';
  }

  @override
  void onClose() {
    targetPhoneController.dispose();
    super.onClose();
  }
}

class _ShareesDialog extends StatelessWidget {
  const _ShareesDialog({required this.items});

  final List<JsonMap> items;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('被分享者'),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? const Text('暂无被分享者')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stringValue(
                                  item['targetNickName'] ??
                                      item['targetPhoneMasked'],
                                  fallback: '--',
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stringValue(item['targetPhoneMasked']),
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          stringValue(item['status'], fallback: '未知'),
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
