import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:car/app/routes/router_instance.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/reference_ui.dart';
import 'package:car/app/routes/route_arguments.dart';
import 'mileage_controller.dart';
import 'package:car/models/vehicle/record_models.dart';

class MileageView extends GetView<MileageController> {
  const MileageView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '里程记录',
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
              _buildSummary(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildSummary() {
    return ReferenceCard(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(
            '总里程',
            '${(controller.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
          ),
          _summaryItem('行程次数', '${controller.trips.length} 次'),
          _summaryItem(
            '平均速度',
            '${controller.averageSpeed.toStringAsFixed(1)} km/h',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ],
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
    if (controller.groups.isEmpty) {
      return const EmptyState(
        message: '当前时间段暂无行程数据',
        icon: CupertinoIcons.arrow_right_arrow_left,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      itemCount: controller.groups.length,
      itemBuilder: (_, index) => _buildGroup(controller.groups[index]),
    );
  }

  Widget _buildGroup(MileageTripGroup group) {
    return ReferenceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.date,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${group.trips.length} 段 · ${(group.totalDistanceMeters / 1000).toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 1,
            child: ColoredBox(color: AppColors.divider),
          ),
          ...group.trips.asMap().entries.map(
            (entry) => _tripTile(entry.key + 1, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _tripTile(int index, TrackTrip trip) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.playback,
        arguments: PlaybackRouteArgs(
          controller.device!,
          startTime: _parseTripTime(trip.startTime),
          endTime: _parseTripTime(trip.endTime),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_clock(trip.startTime)} - ${_clock(trip.endTime)}\n${(trip.distanceMeters / 1000).toStringAsFixed(2)} km · ${_duration(trip.durationMilliseconds)}',
                style: const TextStyle(height: 1.5),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  String _clock(String value) =>
      value.contains(' ') ? value.split(' ').last : value;
  String _duration(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    if (minutes >= 60) return '${minutes ~/ 60}小时${minutes % 60}分';
    if (minutes > 0) return '$minutes分钟';
    return '${milliseconds ~/ 1000}秒';
  }

  DateTime? _parseTripTime(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value.replaceAll(' ', 'T'));
  }
}
