import 'package:get/get.dart';

import '../../model/message/msg_model.dart';
import '../../utils/Logger.dart';
import 'messages_repository.dart';

class MessagesController extends GetxController {
  final MessagesRepository _repository = MessagesRepository();

  // 存储消息对象列表
  final messages = <MessageModel>[].obs;
  final isLoading = false.obs;

  // 分页相关
  final totalCount = 0.obs;
  final pageSize = 10.obs;
  final totalPage = 0.obs;
  final currPage = 1.obs;

  @override
  void onInit() async {
    super.onInit();
    if (await checkLoginStatus()) {
      await loadMessages();
    }
  }

  Future<bool> checkLoginStatus() async {
    try {
      final token = await _repository.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadMessages() async {
    try {
      isLoading.value = true;
      final response = await _repository.fetchMessages();
      if (response.data != null && response.data['code'] == 0) {
        final data = response.data['data'];

        if (data != null) {
          // 更新分页信息
          totalCount.value = data['totalCount'] ?? 0;
          pageSize.value = data['pageSize'] ?? 10;
          totalPage.value = data['totalPage'] ?? 0;
          currPage.value = data['currPage'] ?? 1;

          // 解析消息列表
          final List<dynamic> list = data['list'] ?? [];
          messages.value = list
              .map((json) => MessageModel.fromJson(json))
              .toList();

          Log.i('成功加载 ${messages.length} 条消息');
        }
      } else {
        Log.e('响应错误: ${response.data['msg']}');
      }
    } catch (e) {
      Log.e('加载消息失败: $e');
      Get.snackbar('错误', '加载消息失败');
    } finally {
      isLoading.value = false;
    }
  }

  // 刷新消息
  Future<void> refreshMessages() async {
    currPage.value = 1;
    await loadMessages();
  }

  // 加载更多（如果需要分页）
  Future<void> loadMoreMessages() async {
    if (currPage.value < totalPage.value) {
      currPage.value++;
      await loadMessages();
    }
  }

  @override
  void onClose() {
    messages.clear();
    super.onClose();
  }
}
