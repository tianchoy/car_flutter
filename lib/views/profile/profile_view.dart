import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../shared/widgets/app_diago.dart';
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
                ? CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    onPressed: () {
                      _showDiago(context);
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
          ],
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
