import 'package:get/get.dart';

import 'privacy_consent_controller.dart';

class PrivacyConsentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyConsentController>(() => PrivacyConsentController());
  }
}
