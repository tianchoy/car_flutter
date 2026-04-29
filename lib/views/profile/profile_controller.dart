import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ProfileRepository _repository = ProfileRepository();
  final isLoading = true.obs;
  final profile = <String, dynamic>{}.obs;

  late TabController tabController;
  final List<String> tabs = ['Profile', 'Settings', 'Stats', 'Activity'];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabs.length, vsync: this);
    // loadProfile();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // Future<void> loadProfile() async {
  //   try {
  //     isLoading.value = true;
  //     profile.value = await _repository.fetchProfile();
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load profile');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void refreshProfile() {
    // loadProfile();
  }
}
