import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'messages_repository.dart';

class MessagesController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final MessagesRepository _repository = MessagesRepository();
  final isLoading = true.obs;
  final messages = <String>[].obs;

  late TabController tabController;
  final List<String> tabs = ['All', 'Unread', 'Important', 'Archived'];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabs.length, vsync: this);
    // loadMessages();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // Future<void> loadMessages() async {
  //   try {
  //     isLoading.value = true;
  //     messages.value = await _repository.fetchMessages();
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load messages');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void refreshMessages() {
    // loadMessages();
  }
}
