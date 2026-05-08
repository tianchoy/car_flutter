import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IsLogin extends StatelessWidget {
  const IsLogin({super.key});

  @override

  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: () {
          Get.toNamed('/login');
        },
        child: const Text('请登录以获取更多功能'),
      ),
    );
  }
}
