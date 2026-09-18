import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../app/routes/router_instance.dart';
import '../../services/app_links.dart';
import '../../services/url.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/reference_ui.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '个人中心',
      showBottomNavBar: true,
      body: Obx(
        () => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppRefreshControl(onRefresh: controller.refresh),
            SliverPadding(
              // 底部留 18：版本号尽量下移贴近底部，但不会被 TabBar 遮挡
              //（MainScaffold 已为 TabBar 预留了 50 的高度）。
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildUserCard(),
                  if (controller.isLoggedIn.value) ...[
                    _buildVehicleCard(),
                    _buildServiceCard(context),
                  ] else
                    _buildLoginHint(),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      AppConfig.appVersionLabel,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final user = controller.profile.value;
    final loggedIn = controller.isLoggedIn.value;
    final displayName = user?.userName.isNotEmpty == true
        ? user!.userName
        : loggedIn
        ? '车主用户'
        : '点击登录';
    final subtitle = user?.phoneNumber.isNotEmpty == true
        ? user!.phoneNumber
        : loggedIn
        ? '查看个人信息'
        : '登录后管理车辆和设备';

    return ReferenceCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: loggedIn ? () => Get.toNamed(Routes.userInfo) : _goLogin,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 14, 22),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.person,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
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
    );
  }

  Widget _buildLoginHint() {
    return ReferenceCard(
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.lock_open,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          const Text(
            '登录后查看我的车辆',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: _goLogin,
              child: const Text('立即登录'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return ReferenceCard(
      padding: EdgeInsets.zero,
      child: _menu(
        icon: CupertinoIcons.car_detailed,
        title: '我的车辆',
        subtitle: '管理已绑定的车辆和设备',
        badge: '${controller.vehicleCount.value}',
        onTap: () => Get.toNamed(Routes.vehicleList),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context) {
    return ReferenceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _menu(
            icon: CupertinoIcons.creditcard,
            title: '平台续费',
            subtitle: '延长设备服务时间',
            onTap: () => Get.toNamed(Routes.renewal),
          ),
          const _MenuDivider(),
          _menu(
            icon: CupertinoIcons.chat_bubble_2,
            title: '人工客服',
            subtitle: '08:00-24:00，获取帮助与支持',
            onTap: () => LegalLinks.showCustomerService(context),
          ),
          const _MenuDivider(),
          _menu(
            icon: CupertinoIcons.square_arrow_left,
            title: '退出登录',
            subtitle: '安全退出当前账号',
            danger: true,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? AppColors.danger : AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
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
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('确定要退出当前账号吗？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.logout();
  }

  void _goLogin() => Get.toNamed(Routes.login);
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 70, right: 16),
    child: SizedBox(
      // 必须显式给宽度：否则在 Column 中会被压成 0 宽，分割线根本看不见。
      width: double.infinity,
      height: 1,
      child: ColoredBox(color: AppColors.divider),
    ),
  );
}
