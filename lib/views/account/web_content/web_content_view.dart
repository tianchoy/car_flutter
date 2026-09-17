import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
import 'web_content_controller.dart';

class WebContentView extends GetView<WebContentController> {
  const WebContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = controller.uri;
    return MainScaffold(
      title: controller.title.isEmpty ? '内容详情' : controller.title,
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(() {
        if (controller.errorMessage.value.isNotEmpty) {
          return _errorView(controller.errorMessage.value);
        }
        if (uri == null) return _errorView('链接无效，无法打开');
        final webController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (_) {},
              onPageFinished: (_) => controller.markLoaded(),
              onWebResourceError: (_) => controller.markError(),
            ),
          )
          ..loadRequest(uri);
        return Stack(
          children: [
            WebViewWidget(controller: webController),
            if (controller.isLoading.value)
              const Center(child: AppLoadingIndicator()),
          ],
        );
      }),
    );
  }

  Widget _errorView(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ReferenceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.danger,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ReferenceButton(label: '返回', filled: false, onPressed: Get.back),
          ],
        ),
      ),
    ),
  );
}
