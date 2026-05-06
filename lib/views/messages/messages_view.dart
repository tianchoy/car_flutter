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
      body: Obx(() {
        if (controller.isLoading.value && controller.messages.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.messages.isEmpty) {
          return Center(child: Text('暂无消息'));
        }

        return ListView.builder(
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  message.content,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text('消息ID: ${message.messageId}'),
                    Text('时间: ${message.createTime}'),
                    if (message.readTime != null)
                      Text('已读: ${message.readTime}'),
                  ],
                ),
                trailing: _getStatusIcon(message.status),
                onTap: () {
                  // 处理消息点击
                  Get.snackbar('消息详情', message.content);
                },
              ),
            );
          },
        );
      }),
    );
  }

  Widget _getStatusIcon(int status) {
    switch (status) {
      case 0:
        return Icon(Icons.check_circle, color: Colors.green);
      default:
        return Icon(Icons.access_time, color: Colors.orange);
    }
  }
}
