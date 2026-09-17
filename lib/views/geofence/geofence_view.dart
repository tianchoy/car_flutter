import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/components/widget/map_tile.dart';
import 'package:car/shared/widgets/main_scaffold.dart';
import 'package:car/shared/widgets/reference_ui.dart';
import 'geofence_controller.dart';

class GeofenceView extends GetView<GeofenceController> {
  const GeofenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: '地理围栏',
      showBackButton: true,
      showBottomNavBar: false,
      body: Obx(
        () => Stack(
          children: [
            Positioned.fill(child: _buildMap()),
            Positioned(top: 12, left: 12, right: 12, child: _buildMapStatus()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStatus() {
    final selected = controller.selectedFence.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.shield, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.isDrawing.value
                  ? '正在绘制${controller.drawingMode.value == 'circle' ? '圆形' : '多边形'}围栏'
                  : selected?.name ?? '选择围栏或开始绘制',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          StatusPill(
            label: controller.isDrawing.value
                ? '绘制中'
                : '${controller.fences.length} 个围栏',
            online: controller.isDrawing.value,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Obx(() {
      final expanded = controller.fenceListExpanded.value;
      return Container(
        // 收起时不展示整行白色圆角面板，只保留圆形向上箭头浮在底部。
        decoration: expanded
            ? const BoxDecoration(
                color: AppColors.page,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 12),
                ],
              )
            : null,
        child: _buildBottomPanelContent(context, expanded),
      );
    });
  }

  Widget _buildBottomPanelContent(BuildContext context, bool expanded) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!expanded)
                // 收起态：底部只显示一个圆形向上箭头按钮，点击即展开。
                Padding(
                  // 收起态的圆形箭头贴底显示，留出底部安全区（iOS Home Indicator）
                  // 的高度，避免与系统返回横线重叠。
                  padding: const EdgeInsets.only(top: 8, bottom: 28),
                  child: Center(
                    child: GestureDetector(
                      onTap: controller.toggleFenceList,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.chevron_up,
                          size: 24,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                // 展开态：不再显示任何箭头，仅保留顶部短横线，按住下滑即全部隐藏。
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 4) controller.collapseFenceList();
                  },
                  child: SizedBox(
                    height: 26,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildToolbar(context),
                _buildFenceList(context),
              ],
            ],
          ),
    );
  }

  Widget _buildMap() {
    return MapTile(
      isLoading: controller.isLoading.value,
      // 页面提示统一改为从顶部向下弹出的 AppToast，不再用地图浮层展示。
      errMsg: '',
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      initialZoom: 12,
      mapController: controller.mapController,
      clusterMarkers: false,
      polygons: controller.polygons,
      circles: controller.circles,
      markers: controller.mapMarkers,
      onMapTap: controller.handleMapTap,
    );
  }

  LatLng get _mapCenter {
    final fence = controller.selectedFence.value;
    if (fence != null) {
      final points = controller.parseArea(fence.area, fence.isCircle);
      if (points.isNotEmpty) return points.first;
    }
    final points = controller.draftPoints;
    if (points.isNotEmpty) return points.first;
    final initial = controller.initialCenter.value;
    if (initial != null) return initial;
    return const LatLng(39.9042, 116.4074);
  }

  Widget _buildToolbar(BuildContext context) {
    final isCircle = controller.drawingMode.value == 'circle';
    return ReferenceCard(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: controller.drawingMode.value,
                  children: const {
                    'polygon': Text('多边形'),
                    'circle': Text('圆形'),
                  },
                  onValueChanged: (value) {
                    if (value != null) controller.setDrawingMode(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 绘制过程中禁用，避免与下方的「重置 / 保存」操作混淆。
              ReferenceButton(
                label: '绘制',
                onPressed: controller.isDrawing.value
                    ? null
                    : controller.startDrawing,
              ),
            ],
          ),
          if (controller.isDrawing.value)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCircle
                          ? controller.circleCenter.value == null
                                ? '点击地图确定圆心，再点击确定半径'
                                : '半径 ${controller.circleRadius.value.toStringAsFixed(0)} 米'
                          : '已添加 ${controller.draftPoints.length} 个顶点，至少需要 3 个',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    onPressed: controller.clearDraft,
                    child: const Text('重置'),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    onPressed: controller.canFinishDrawing
                        ? () => _save(context)
                        : null,
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFenceList(BuildContext context) {
    return SizedBox(
      // 与上方工具栏合计不超过可用高度，避免底部溢出。
      height: 190,
      child: controller.fences.isEmpty
          ? const EmptyState(message: '暂无围栏数据', icon: CupertinoIcons.shield)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: controller.fences.length,
              itemBuilder: (context, index) {
                final fence = controller.fences[index];
                final selected = controller.selectedFence.value?.id == fence.id;
                return ReferenceCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.zero,
                  color: selected
                      ? const Color(0xFFEAF3FF)
                      : CupertinoColors.white,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () => controller.selectFence(fence),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            fence.isCircle
                                ? CupertinoIcons.circle
                                : CupertinoIcons.square_grid_2x2,
                            color: selected
                                ? AppColors.primary
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fence.name,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${fence.isCircle ? '圆形' : '多边形'}围栏 · 已绑定 ${fence.deviceCount} 台',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReferenceIconButton(
                            icon: CupertinoIcons.ellipsis,
                            color: AppColors.secondaryText,
                            onPressed: () => _showFenceActions(context, fence),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showFenceActions(BuildContext context, dynamic fence) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          fence.name,
          style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'devices'),
            child: const Text(
              '管理设备',
              style: TextStyle(fontSize: 15),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: const Text('编辑', style: TextStyle(fontSize: 15)),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('删除', style: TextStyle(fontSize: 15)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(fontSize: 15)),
        ),
      ),
    );
    if (!context.mounted) return;
    controller.selectFence(fence);
    if (action == 'edit') {
      controller.editSelectedFence();
    } else if (action == 'delete') {
      await _confirmDelete(context);
    } else if (action == 'devices') {
      await _showDeviceManager(context);
    }
  }

  Future<void> _showDeviceManager(BuildContext context) async {
    final fence = controller.selectedFence.value;
    if (fence == null) return;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _DeviceManagerSheet(controller: controller),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final fence = controller.selectedFence.value;
    if (fence == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('删除围栏'),
        content: Text('确定删除“${fence.name}”吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteSelectedFence();
  }

  Future<void> _save(BuildContext context) async {
    final selectedFence = controller.selectedFence.value;
    final nameController = TextEditingController(
      text: selectedFence?.name ?? '',
    );
    var alarmType = selectedFence?.alarmType ?? 1;
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: Text(
            selectedFence == null ? '保存围栏' : '编辑围栏',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: nameController,
                  autofocus: true,
                  placeholder: '请输入围栏名称',
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  style: const TextStyle(fontSize: 15),
                  placeholderStyle: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.placeholderText,
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '告警类型',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _alarmTypeLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => alarmType = i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == alarmType
                              ? AppColors.primary.withValues(alpha: .1)
                              : const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: i == alarmType
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _alarmTypeLabels[i],
                              style: TextStyle(
                                fontSize: 15,
                                color: i == alarmType
                                    ? AppColors.primary
                                    : AppColors.text,
                                fontWeight: i == alarmType
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (i == alarmType)
                              const Icon(
                                CupertinoIcons.check_mark,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, nameController.text),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await controller.saveFence(name: name, alarmType: alarmType);
    }
  }
}

class _DeviceManagerSheet extends StatelessWidget {
  const _DeviceManagerSheet({required this.controller});

  final GeofenceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SafeArea(
        child: Container(
          color: CupertinoColors.systemBackground,
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '围栏设备管理',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ReferenceIconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CupertinoIcons.xmark,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  // 与上方「多边形 / 圆形」保持一致的滑动分段控件样式。
                  child: Obx(
                    () => CupertinoSlidingSegmentedControl<int>(
                      groupValue: controller.deviceTab.value,
                      children: const {
                        0: Text('已绑定'),
                        1: Text('未绑定'),
                      },
                      onValueChanged: (value) {
                        if (value != null) controller.deviceTab.value = value;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: controller.isLoadingDevices.value
                    ? const Center(child: AppLoadingIndicator())
                    : _buildDeviceList(),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ReferenceButton(
                  label: controller.deviceTab.value == 0 ? '批量解绑' : '批量绑定',
                  expand: true,
                  onPressed: controller.deviceTab.value == 0
                      ? controller.selectedBoundDeviceNos.isEmpty
                            ? null
                            : controller.unbindSelectedDevices
                      : controller.selectedUnboundDeviceNos.isEmpty
                      ? null
                      : controller.bindSelectedDevices,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final bound = controller.deviceTab.value == 0;
    final devices = bound ? controller.boundDevices : controller.unboundDevices;
    final selected = bound
        ? controller.selectedBoundDeviceNos
        : controller.selectedUnboundDeviceNos;
    if (devices.isEmpty) {
      return EmptyState(message: bound ? '暂无已绑定设备' : '暂无可绑定设备');
    }
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (_, index) {
        final device = devices[index];
        final deviceNo = controller.deviceNoOf(device);
        final checked = selected.contains(deviceNo);
        return CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: Size.zero,
          onPressed: () =>
              controller.toggleDeviceSelection(device, bound: bound),
          child: Row(
            children: [
              Icon(
                checked
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: checked ? AppColors.primary : AppColors.secondaryText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.deviceTitle(device),
                      style: const TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      deviceNo.isEmpty ? '--' : deviceNo,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

const List<String> _alarmTypeLabels = [
  '不告警',
  '出入告警',
  '出告警',
  '入告警',
];


