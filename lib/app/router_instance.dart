import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../shared/services/startup_route_service.dart';
import 'package:car/views/account/change_password/change_password_binding.dart';
import 'package:car/views/account/change_password/change_password_view.dart';
import 'package:car/views/account/forgot_password/forgot_password_binding.dart';
import 'package:car/views/account/forgot_password/forgot_password_view.dart';
import 'package:car/views/account/pay_devices/pay_device_list_binding.dart';
import 'package:car/views/account/pay_devices/pay_device_list_view.dart';
import 'package:car/views/account/register/register_binding.dart';
import 'package:car/views/account/register/register_view.dart';
import 'package:car/views/account/renewal/renewal_binding.dart';
import 'package:car/views/account/renewal/renewal_view.dart';
import 'package:car/views/account/scan_code/scan_code_binding.dart';
import 'package:car/views/account/scan_code/scan_code_view.dart';
import 'package:car/views/account/user_info/user_info_binding.dart';
import 'package:car/views/account/user_info/user_info_view.dart';
import 'package:car/views/account/vehicles/detail/vehicle_detail_binding.dart';
import 'package:car/views/account/vehicles/detail/vehicle_detail_view.dart';
import 'package:car/views/account/vehicles/list/vehicle_list_binding.dart';
import 'package:car/views/account/vehicles/list/vehicle_list_view.dart';
import 'package:car/views/account/web_content/web_content_binding.dart';
import 'package:car/views/account/web_content/web_content_view.dart';
import 'package:car/views/device/commands/commands_binding.dart';
import 'package:car/views/device/commands/commands_view.dart';
import 'package:car/views/device/detail/detail_binding.dart';
import 'package:car/views/device/detail/detail_view.dart';
import 'package:car/views/device/share/device_share_binding.dart';
import 'package:car/views/device/share/device_share_view.dart';
import 'package:car/views/device/add/add_device_binding.dart';
import 'package:car/views/device/add/add_device_view.dart';
import 'package:car/views/device/list/device_list_binding.dart';
import 'package:car/views/device/list/device_list_view.dart';
import 'package:car/views/geofence/geofence_binding.dart';
import 'package:car/views/geofence/geofence_view.dart';
import 'package:car/views/home/home_binding.dart';
import 'package:car/views/home/home_view.dart';
import 'package:car/views/login/login_bindings.dart';
import 'package:car/views/login/login_view.dart';
import 'package:car/views/messages/messages_binding.dart';
import 'package:car/views/messages/messages_view.dart';
import 'package:car/views/profile/profile_binding.dart';
import 'package:car/views/profile/profile_view.dart';
import 'package:car/views/vehicle/mileage/mileage_binding.dart';
import 'package:car/views/vehicle/mileage/mileage_view.dart';
import 'package:car/views/vehicle/playback/playback_binding.dart';
import 'package:car/views/vehicle/playback/playback_view.dart';
import 'package:car/views/vehicle/stop_record/stop_record_binding.dart';
import 'package:car/views/vehicle/stop_record/stop_record_view.dart';
import 'package:car/views/vehicle/tracking/tracking_binding.dart';
import 'package:car/views/vehicle/tracking/tracking_view.dart';
import 'routes.dart';

export 'routes.dart';

class _StartupView extends StatelessWidget {
  const _StartupView();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class AppRouter {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.startup,
      page: () => const _StartupView(),
      binding: BindingsBuilder(() {
        Get.put<StartupController>(StartupController());
      }),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.messages,
      page: () => const MessagesView(),
      binding: MessagesBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBindings(),
    ),
    GetPage(
      name: Routes.detail,
      page: () => const DetailView(),
      binding: DetailBinding(),
    ),
    GetPage(
      name: Routes.geofence,
      page: () => const GeofenceView(),
      binding: GeofenceBinding(),
    ),
    GetPage(
      name: Routes.deviceList,
      page: () => const DeviceListView(),
      binding: DeviceListBinding(),
    ),
    GetPage(
      name: Routes.addDevice,
      page: () => const AddDeviceView(),
      binding: AddDeviceBinding(),
    ),
    GetPage(
      name: Routes.scanCode,
      page: () => const ScanCodeView(),
      binding: ScanCodeBinding(),
    ),
    GetPage(
      name: Routes.playback,
      page: () => const PlaybackView(),
      binding: PlaybackBinding(),
    ),
    GetPage(
      name: Routes.tracking,
      page: () => const TrackingView(),
      binding: TrackingBinding(),
    ),
    GetPage(
      name: Routes.mileage,
      page: () => const MileageView(),
      binding: MileageBinding(),
    ),
    GetPage(
      name: Routes.stopRecord,
      page: () => const StopRecordView(),
      binding: StopRecordBinding(),
    ),
    GetPage(
      name: Routes.deviceShare,
      page: () => const DeviceShareView(),
      binding: DeviceShareBinding(),
    ),
    GetPage(
      name: Routes.commands,
      page: () => const CommandsView(),
      binding: CommandsBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: Routes.userInfo,
      page: () => const UserInfoView(),
      binding: UserInfoBinding(),
    ),
    GetPage(
      name: Routes.vehicleList,
      page: () => const VehicleListView(),
      binding: VehicleListBinding(),
    ),
    GetPage(
      name: Routes.vehicleDetail,
      page: () => const VehicleDetailView(),
      binding: VehicleDetailBinding(),
    ),
    GetPage(
      name: Routes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: Routes.renewal,
      page: () => const RenewalView(),
      binding: RenewalBinding(),
    ),
    GetPage(
      name: Routes.payDeviceList,
      page: () => const PayDeviceListView(),
      binding: PayDeviceListBinding(),
    ),
    GetPage(
      name: Routes.webContent,
      page: () => const WebContentView(),
      binding: WebContentBinding(),
    ),
  ];
}
