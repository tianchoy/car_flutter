import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../model/message/msg_model.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/reference_ui.dart';
import 'messages_controller.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '消息',
      body: Obx(() {
        if (controller.isLoading.value && controller.messages.isEmpty) {
          return const Center(child: AppLoadingIndicator());
        }
        return ReferencePage(
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppRefreshControl(
                onRefresh: controller.refreshMessages,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == 0) return _buildUnreadBanner();
                    if (index == controller.messages.length + 1) {
                      return _buildLoadMore();
                    }
                    return _buildMessageCard(
                      context,
                      controller.messages[index - 1],
                    );
                  }, childCount: controller.messages.length + 2),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildUnreadBanner() {
    final count = controller.unreadCount.value;
    final fresh = controller.newMessageCount.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 轮询到新消息时不直接刷新列表，先提示数量，用户点击确认后再展开。
        if (fresh > 0)
          ReferenceCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.zero,
            color: const Color(0xFFEAF3FF),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              onPressed: controller.loadNewMessages,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.mail_solid,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '有 $fresh 条新消息，点击查看',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ReferenceCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          color: count > 0 ? const Color(0xFFEAF3FF) : CupertinoColors.white,
          child: Row(
            children: [
              Icon(
                count > 0 ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
                color: count > 0 ? AppColors.primary : AppColors.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count > 0 ? '有 $count 条未读消息' : '暂无未读消息',
                  style: TextStyle(
                    color: count > 0
                        ? AppColors.primaryDark
                        : AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(radius: 8),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(BuildContext context, MessageModel message) {
    final isUnread = message.status == 1;
    return ReferenceCard(
      padding: EdgeInsets.zero,
      color: isUnread ? const Color(0xFFFCFEFF) : CupertinoColors.white,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => _showDetail(context, message),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _typeIcon(message.messageType, isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _typeName(message.messageType),
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(message.createTime),
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      message.content.isEmpty ? '暂无消息内容' : message.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread
                            ? AppColors.text
                            : AppColors.secondaryText,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: isUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          message.createTime.isEmpty
                              ? '--'
                              : message.createTime,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (isUnread)
                          const Text(
                            '未读',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                            ),
                          )
                        else
                          const Text(
                            '已读',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(int type, bool unread) {
    final icon = switch (type) {
      1 => CupertinoIcons.exclamationmark_triangle_fill,
      2 => CupertinoIcons.car_detailed,
      3 => CupertinoIcons.creditcard,
      _ => CupertinoIcons.bell,
    };
    final color = unread ? AppColors.primary : AppColors.secondaryText;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  String _typeName(int type) => switch (type) {
    1 => '设备告警',
    2 => '车辆动态',
    3 => '服务通知',
    _ => '系统消息',
  };

  String _relativeTime(String value) {
    final date = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (date == null) return '';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes}分钟前';
    if (difference.inDays < 1) return '${difference.inHours}小时前';
    if (difference.inDays < 7) return '${difference.inDays}天前';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  Widget _buildLoadMore() {
    if (controller.messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: EmptyState(message: '暂无消息', icon: CupertinoIcons.bell),
      );
    }
    if (controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CupertinoActivityIndicator(),
      );
    }
    if (controller.currPage.value >= controller.totalPage.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多消息了',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ),
      );
    }
    return CupertinoButton(
      onPressed: controller.loadMoreMessages,
      child: const Text('加载更多'),
    );
  }

  Future<void> _showDetail(BuildContext context, MessageModel message) async {
    await controller.markAsRead(message);
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(_typeName(message.messageType)),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content.isEmpty ? '暂无消息内容' : message.content,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '时间：${message.createTime.isEmpty ? '--' : message.createTime}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
