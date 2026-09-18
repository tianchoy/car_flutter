import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'package:car/models/vehicle/record_models.dart';
import 'stop_record_controller.dart';

class StopRecordView extends GetView<StopRecordController> {
  const StopRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '停车记录',
      showBackButton: true,
      showBottomNavBar: false,
      body: ReferencePage(
        child: Obx(
          () => Column(
            children: [
              DateRangeCard(
                startTime: controller.startTime.value,
                endTime: controller.endTime.value,
                horizontal: true,
                onPickStart: () =>
                    controller.pickDate(start: true, context: context),
                onPickEnd: () =>
                    controller.pickDate(start: false, context: context),
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (controller.isLoading.value) {
      return const Center(child: AppLoadingIndicator());
    }
    if (controller.errorMessage.value.isNotEmpty) {
      return EmptyState(
        message: controller.errorMessage.value,
        icon: CupertinoIcons.exclamationmark_circle,
      );
    }
    if (controller.records.isEmpty) {
      return const EmptyState(
        message: '当前时间段暂无停车数据',
        icon: CupertinoIcons.placemark,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      itemCount: controller.records.length,
      itemBuilder: (_, index) => _buildRecord(controller.records[index]),
    );
  }

  Widget _buildRecord(StopRecord record) {
    return ReferenceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(CupertinoIcons.play_circle, '开始时间', record.startTime),
          _row(CupertinoIcons.stop_circle, '结束时间', record.endTime),
          _row(
            CupertinoIcons.timer,
            '停留时长',
            _duration(record.durationMilliseconds),
          ),
          if (record.address.isNotEmpty)
            _row(CupertinoIcons.location, '停车位置', record.address)
          else if (record.latitude != null && record.longitude != null)
            _locationRow(record),
        ],
      ),
    );
  }

  /// 停车位置：还没有中文地址时展示「解析中文地址」，点击后调用逆地理接口，
  /// 解析成功即把结果回填到该条记录、原地展示为中文地址。
  Widget _locationRow(StopRecord record) {
    final parsing = controller.isParsing(record);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.location,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 9),
          const Text(
            '停车位置：',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
          Expanded(
            child: GestureDetector(
              onTap: parsing ? null : () => controller.parseAddress(record),
              child: Text(
                parsing ? '解析中…' : '解析中文地址',
                style: const TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 9),
          Text(
            '$label：',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              // 地址可能较长，允许两行并在超长时省略，避免撑破卡片。
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _duration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remaining = seconds % 60;
    if (hours > 0) return '$hours小时$minutes分$remaining秒';
    if (minutes > 0) return '$minutes分$remaining秒';
    return '$remaining秒';
  }
}
