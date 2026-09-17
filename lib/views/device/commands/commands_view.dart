import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:car/shared/widgets/app_toast.dart';

import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
import 'package:car/model/device/command_models.dart';
import 'commands_controller.dart';

class CommandsView extends GetView<CommandsController> {
  const CommandsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '指令中心',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(
        () => ReferencePage(
          child: Column(
            children: [
              _buildDeviceCard(),
              _buildTabs(),
              Expanded(
                child: controller.deviceId.isEmpty
                    ? const EmptyState(
                        message: '未获取到设备信息，请返回车辆详情后重试',
                        icon: CupertinoIcons.exclamationmark_triangle,
                      )
                    : controller.activeTab.value == 0
                    ? _buildSendPage(context)
                    : _buildHistoryPage(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2878DD), Color(0xFF65A5F5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332878DD),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.car_detailed,
            color: CupertinoColors.white,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前设备',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.deviceIdentity.isEmpty
                      ? '--'
                      : controller.deviceIdentity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '设备 ID',
                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                controller.deviceId.isEmpty ? '--' : controller.deviceId,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ReferenceCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(4),
        child: Row(children: [_tab('下发指令', 0), _tab('指令记录', 1)]),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = controller.activeTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.activeTab.value = index;
          if (index == 1 && controller.history.isEmpty) {
            controller.loadHistory(reset: true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? CupertinoColors.white : AppColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendPage(BuildContext context) {
    if (controller.isLoading.value && controller.availableCommands.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }
    if (controller.errorMessage.value.isNotEmpty &&
        controller.availableCommands.isEmpty) {
      return EmptyState(
        message: controller.errorMessage.value,
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        SectionTitle(
          '可用指令',
          action: '刷新',
          onTap: controller.loadAvailableCommands,
        ),
        const SizedBox(height: 8),
        if (controller.availableCommands.isEmpty)
          const ReferenceCard(
            child: EmptyState(
              message: '暂无可用指令，请确认设备状态后重试',
              icon: CupertinoIcons.paperplane,
            ),
          )
        else
          ...controller.availableCommands.map(_buildCommandCard),
        if (controller.selectedCommand.value != null)
          _buildParameterCard(context, controller.selectedCommand.value!),
      ],
    );
  }

  Widget _buildCommandCard(CommandTemplate command) {
    final selected = controller.selectedCommand.value?.id == command.id;
    return ReferenceCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      color: selected ? const Color(0xFFF0F7FF) : CupertinoColors.white,
      child: GestureDetector(
        onTap: command.allowed
            ? () => controller.selectCommand(command)
            : () => AppToast.show('提示', '该指令不允许在 App 端下发'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : CupertinoColors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                command.allowed
                    ? CupertinoIcons.paperplane
                    : CupertinoIcons.nosign,
                color: command.allowed
                    ? AppColors.primary
                    : AppColors.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (command.code.isNotEmpty || command.remark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          [
                            command.code,
                            command.remark,
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              StatusPill(
                label: !command.allowed
                    ? '不可下发'
                    : command.needsParameters
                    ? '需填参数'
                    : '无需参数',
                online: command.allowed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterCard(BuildContext context, CommandTemplate command) {
    return ReferenceCard(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('确认指令'),
          const SizedBox(height: 4),
          Text(
            command.name,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          if (command.paramSchema.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                '该指令无需填写参数',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
          ...command.paramSchema.map(_buildParameterField),
          if (controller.parameterErrors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                controller.parameterErrors.values.first,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          const SizedBox(height: 18),
          Obx(
            () => ReferenceButton(
              label: '确认下发指令',
              icon: const Icon(CupertinoIcons.paperplane),
              expand: true,
              loading: controller.isSending.value,
              onPressed: controller.isSending.value
                  ? null
                  : () => _confirmSend(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterField(CommandParameter parameter) {
    final value = controller.parameterValue(parameter);
    final error = controller.parameterErrors[parameter.key];
    final label = '${parameter.label}${parameter.required ? ' *' : ''}';
    if (parameter.type == 'select') {
      final option = parameter.options.firstWhereOrNull(
        (item) => item.value == value,
      );
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: GestureDetector(
          onTap: () => _selectOption(parameter),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error == null ? AppColors.divider : AppColors.danger,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option?.label ??
                            (value.isEmpty ? parameter.placeholder : value),
                        style: TextStyle(
                          color: value.isEmpty
                              ? AppColors.secondaryText
                              : AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  color: AppColors.secondaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ReferenceInput(
        hint: parameter.placeholder.isEmpty ? label : parameter.placeholder,
        keyboardType: parameter.type == 'number'
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onChanged: (value) => controller.updateParameter(parameter, value),
        errorText: error,
      ),
    );
  }

  Future<void> _selectOption(CommandParameter parameter) async {
    final option = await showCupertinoModalPopup<CommandOption>(
      context: Get.context!,
      builder: (context) => CupertinoActionSheet(
        title: Text('请选择${parameter.label}'),
        actions: parameter.options
            .map(
              (item) => CupertinoActionSheetAction(
                isDefaultAction:
                    controller.parameterValue(parameter) == item.value,
                onPressed: () => Navigator.pop(context, item),
                child: Text(item.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
    if (option != null) controller.updateParameter(parameter, option.value);
  }

  Future<void> _confirmSend(BuildContext context) async {
    if (!controller.validateForm()) return;
    final command = controller.selectedCommand.value;
    if (command == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认下发指令'),
        content: Text('即将向设备下发“${command.name}”，请确认设备当前状态适合执行此操作。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认下发'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.sendSelectedCommand();
  }

  Widget _buildHistoryPage(BuildContext context) {
    if (controller.isHistoryLoading.value && controller.history.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }
    if (controller.history.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionTitle(
            '指令记录',
            action: '刷新',
            onTap: () => controller.loadHistory(reset: true),
          ),
          const SizedBox(height: 8),
          const ReferenceCard(
            child: EmptyState(message: '暂无指令记录', icon: CupertinoIcons.time),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        AppRefreshControl(
          onRefresh: () => controller.loadHistory(reset: true),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == controller.history.length) {
                return _buildHistoryFooter();
              }
              return _buildHistoryCard(context, controller.history[index]);
            }, childCount: controller.history.length + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, CommandRecord record) {
    final status = record.status;
    final statusLabel = status == '1'
        ? '下发成功'
        : status == '2'
        ? '下发失败'
        : '等待下发';
    final color = status == '1'
        ? AppColors.success
        : status == '2'
        ? AppColors.danger
        : AppColors.warning;
    return ReferenceCard(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => _showDetail(context, record),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusPill(label: statusLabel, online: status == '1'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.time.isEmpty ? '--' : record.time,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              if (record.reason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  record.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '已重试 ${record.retryCount} 次',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '查看详情 ›',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryFooter() {
    if (controller.isHistoryLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    if (!controller.hasMoreHistory.value) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多记录了',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ),
      );
    }
    return CupertinoButton(
      onPressed: () => controller.loadHistory(),
      child: const Text('加载更多'),
    );
  }

  Future<void> _showDetail(BuildContext context, CommandRecord record) async {
    await controller.openDetail(record);
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        final detail = controller.detailRecord.value ?? record;
        return CupertinoAlertDialog(
          title: const Text('指令详情'),
          content: controller.isDetailLoading.value
              ? const SizedBox(
                  height: 80,
                  child: Center(child: AppLoadingIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _detailRow('指令名称', detail.name),
                      _detailRow(
                        '下发状态',
                        detail.status == '1'
                            ? '下发成功'
                            : detail.status == '2'
                            ? '下发失败'
                            : '等待下发',
                      ),
                      _detailRow('发送时间', detail.time),
                      if (detail.reason.isNotEmpty)
                        _detailRow('结果说明', detail.reason),
                    ],
                  ),
                ),
          actions: [
            if (detail.status == '2' || detail.status == '0')
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.retryRecord(detail);
                },
                child: const Text('重试下发'),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '--' : value)),
        ],
      ),
    );
  }
}
