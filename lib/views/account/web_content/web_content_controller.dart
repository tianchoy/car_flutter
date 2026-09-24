import 'package:get/get.dart';

import 'package:car/app/routes/route_arguments.dart';
import 'web_content_repository.dart';

class WebContentController extends GetxController {
  WebContentController({WebContentRepository? repository})
    : repository = repository ?? const WebContentRepository();

  final WebContentRepository repository;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  late final String title;

  /// 本地资源路径（非空时优先加载，见 [WebContentRouteArgs.assetPath]）。
  late final String assetPath;
  late final Uri? uri;

  @override
  void onInit() {
    super.onInit();
    final args = WebContentRouteArgs.parse(Get.arguments);
    title = args?.title ?? '';
    assetPath = args?.trimmedAssetPath ?? '';
    uri = args?.uri;
    if (uri == null && assetPath.isEmpty) {
      isLoading.value = false;
      errorMessage.value = '链接无效，无法打开';
    }
  }

  void markLoaded() {
    if (!isClosed) isLoading.value = false;
  }

  void markError([String message = '内容加载失败，请检查网络后重试']) {
    if (isClosed) return;
    isLoading.value = false;
    errorMessage.value = message;
  }
}
