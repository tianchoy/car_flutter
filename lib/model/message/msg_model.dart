// 定义消息模型
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
    String toString(dynamic value) => value?.toString() ?? '';
    int toInt(dynamic value) => value as int;

    return MessageModel(
      messageId: toString(json['messageId']),
      content: toString(json['content']),
      messageType: toInt(json['messageType']),
      status: toInt(json['status']),
      createTime: toString(json['createTime']),
      readTime: json['readTime']?.toString(),
      deleted: toInt(json['deleted']),
      userId: toString(json['userId']),
      transactionId: toString(json['transactionId']),
    );
  }
}
