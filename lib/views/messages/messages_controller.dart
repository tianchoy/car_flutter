import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'messages_repository.dart';
import '../../utils/logger.dart';

class MessagesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final MessagesRepository msgRepository = MessagesRepository();
  final isLoading = true.obs;
  final messages = <String>[].obs;

  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    msgRepository.fetchMessages();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> loadMessages() async {
    try {
      isLoading.value = true;
      messages.value = (await msgRepository.fetchMessages()) as List<String>;
      Log.e('messages: $messages.value');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages');
    } finally {
      isLoading.value = false;
    }
  }

  void refreshMessages() {
    // loadMessages();
  }
}
