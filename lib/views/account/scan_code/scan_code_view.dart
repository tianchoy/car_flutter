import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'scan_code_controller.dart';

class ScanCodeView extends GetView<ScanCodeController> {
  const ScanCodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '扫码添加设备',
      showBackButton: true,
      showBottomNavBar: false,
      backgroundColor: CupertinoColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 权限就绪后才挂载相机：避免权限未定时 autoStart 失败，
                  // 也避免与手动 start() 冲突导致「相机启动失败」。
                  Obx(
                    () => controller.cameraReady.value
                        ? MobileScanner(
                            controller: controller.scannerController,
                            onDetect: controller.onDetect,
                            onDetectError: controller.onDetectError,
                            errorBuilder: (_, error) =>
                                _ScannerError(error: error),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => controller.errorMessage.value.isEmpty
                        ? const SizedBox.shrink()
                        : Positioned.fill(
                            child: ColoredBox(
                              color: CupertinoColors.black.withValues(alpha: .6),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.black.withValues(
                                      alpha: .92,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        controller.errorMessage.value,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      CupertinoButton.filled(
                                        onPressed: controller.initCamera,
                                        child: const Text('重试'),
                                      ),
                                      if (controller.errorMessage.value
                                          .contains('系统设置'))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: CupertinoButton(
                                            onPressed:
                                                controller.goToAppSettings,
                                            child: const Text('去设置'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  // 画面中出现多个码时，顶部出现按钮供手动选择扫描哪一个。
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Obx(() {
                      final items = controller.candidates;
                      if (items.length < 2) return const SizedBox.shrink();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '识别到多个码，请选择',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                onPressed: controller.rescan,
                                child: const Text(
                                  '重新扫描',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: items
                                .map(
                                  (value) => CupertinoButton.filled(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    onPressed: () =>
                                        controller.selectCandidate(value),
                                    child: Text(
                                      value.length > 14
                                          ? '${value.substring(0, 14)}…'
                                          : value,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    }),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScannerAction(
                          icon: CupertinoIcons.bolt_fill,
                          label: '手电筒',
                          onPressed: controller.toggleTorch,
                        ),
                        const SizedBox(width: 28),
                        _ScannerAction(
                          icon: CupertinoIcons.camera_rotate,
                          label: '切换摄像头',
                          onPressed: controller.switchCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 整屏展示相机预览，不再显示底部手动输入区。
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _ScannerAction extends StatelessWidget {
  const _ScannerAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: onPressed,
          child: Icon(icon, color: CupertinoColors.white),
        ),
        Text(
          label,
          style: const TextStyle(color: CupertinoColors.white, fontSize: 12),
        ),
      ],
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CupertinoColors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '无法启动相机\n${error.errorDetails?.message ?? '请检查相机权限'}\n\n也可以在下方手动输入设备 ID',
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      ),
    );
  }
}
