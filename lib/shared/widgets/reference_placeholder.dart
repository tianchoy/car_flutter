import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'main_scaffold.dart';
import 'reference_ui.dart';

class ReferencePlaceholderView extends StatelessWidget {
  const ReferencePlaceholderView({
    super.key,
    required this.title,
    this.message = '该功能正在准备中',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: title,
      showBackButton: true,
      showBottomNavBar: false,
      body: ReferencePage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ReferenceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.hammer,
                    color: AppColors.primary,
                    size: 52,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 18),
                  CupertinoButton(onPressed: Get.back, child: const Text('返回')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
