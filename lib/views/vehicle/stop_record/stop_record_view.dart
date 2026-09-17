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
            _row(
              CupertinoIcons.location,
              '停车位置',
              '${record.latitude}, ${record.longitude}',
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
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 9),
          Text(
            '$label：',
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.text)),
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
