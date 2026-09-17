// 定义消息模型
import '../../shared/models/api_response.dart';

class MessageModel {
  final String messageId;
  final String content;
  final int messageType;
  final int status;
  final String createTime;
  final String? readTime;
  final int deleted;
  final String userId;
  final String transactionId;

  MessageModel({
    required this.messageId,
    required this.content,
    required this.messageType,
    required this.status,
    required this.createTime,
    this.readTime,
    required this.deleted,
    required this.userId,
    required this.transactionId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: stringValue(json['messageId']),
      content: stringValue(json['content']),
      messageType: intValue(json['messageType']),
      status: intValue(json['status']),
      createTime: stringValue(json['createTime']),
      readTime: json['readTime'] == null ? null : stringValue(json['readTime']),
      deleted: intValue(json['deleted']),
      userId: stringValue(json['userId']),
      transactionId: stringValue(json['transactionId']),
    );
  }
}
