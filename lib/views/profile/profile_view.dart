import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '个人中心',
      body: Obx(
        () => Column(
          children: [
            Text('Profile:'),
            controller.isLoggedIn.value
                ? ElevatedButton(
                    onPressed: controller.logout,
                    child: Text('退出登录'),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
