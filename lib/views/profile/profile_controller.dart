import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_repository.dart';

class ProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ProfileRepository _repository = ProfileRepository();
  final isLoading = true.obs;
  final profile = <String, dynamic>{}.obs;
  final isLoggedIn = false.obs;

  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    // loadProfile();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> logout() async {
    await _repository.logout();
    Get.offAllNamed('/');
  }

  //   try {
  //     isLoading.value = true;
  //     profile.value = await _repository.fetchProfile();
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load profile');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> isLogin() async {
    isLoggedIn.value = await checkToken();
  }

  Future<bool> checkToken() async {
    return await _repository.checkToken();
  }

  void refreshProfile() {
    // loadProfile();
  }
}
