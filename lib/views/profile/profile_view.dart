import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/widget/app_dialog.dart';
import '../../components/widget/buildBody.dart';
import '../../components/widget/is_login.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '个人中心',
      body: Obx(
        () => BuildBody(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 50,
                  child: const Icon(CupertinoIcons.person_circle),
                ),
                title: Text(
                  controller.profile.value?.username ?? '未登录',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              controller.isLoggedIn.value
                  ? CupertinoButton(
                      color: CupertinoColors.activeBlue,
                      onPressed: () {
                        _showDiago(context);
                        // _showPopup(context);
                      },
                      child: Text(
                        '退出登录',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Container(),

              if (!controller.isLoggedIn.value) IsLogin(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiago(BuildContext context) {
    AppDialog.show(
      context,
      title: '提示',
      content: '确定退出登录吗?',
      onConfirm: () {
        controller.logout();
      },
      onCancel: () {
        print('点击取消');
      },
    );
  }
}
