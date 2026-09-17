import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'user_info_controller.dart';

class UserInfoView extends GetView<UserInfoController> {
  const UserInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '个人信息',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(
        () => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppRefreshControl(onRefresh: controller.load),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SectionTitle('基本信息'),
                  const SizedBox(height: 8),
                  ReferenceCard(
                    child: Column(
                      children: [
                        _infoRow('账号', _text(controller.profile.value?.userName)),
                        _infoRow(
                          '手机号',
                          _text(controller.profile.value?.phoneNumber),
                        ),
                        // 用户来源渠道（APP/小程序/H5/后台录入），
                        // 按接口文档 §3.3 字典映射，非登录体系类型。
                        _infoRow(
                          '类型',
                          _text(controller.profile.value?.userSourceTypeName),
                        ),
                        _infoRow(
                          '创建时间',
                          _text(controller.profile.value?.createTime),
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('安全信息'),
                  const SizedBox(height: 8),
                  ReferenceCard(
                    padding: EdgeInsets.zero,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      minimumSize: Size.zero,
                      onPressed: controller.openChangePassword,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '修改密码',
                                  style: TextStyle(color: AppColors.text),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '修改后需要重新登录',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: AppColors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.isLoading.value)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: AppLoadingIndicator()),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空值统一展示为 '--'。
  String _text(String? value) =>
      (value == null || value.trim().isEmpty) ? '--' : value.trim();

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
