import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'messages_controller.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '消息',
      body: Column(children: [Text('Message')]),
    );
  }
}
