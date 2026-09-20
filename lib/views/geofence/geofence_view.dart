import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:car/widgets/map_tile.dart';
import 'package:car/widgets/main_scaffold.dart';
import 'package:car/widgets/app_bottom_sheet.dart';
import 'package:car/widgets/reference_ui.dart';
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
            // 收起态：底部只显示一个圆形向上箭头按钮，点击即展开；
            // 箭头带上下跳动动画，引导用户点击查看更多内容。
            Padding(
              // 收起态的圆形箭头贴底显示，留出底部安全区（iOS Home Indicator）
              // 的高度，避免与系统返回横线重叠。
              padding: const EdgeInsets.only(top: 8, bottom: 28),
              child: Center(
                child: _BouncingArrowButton(onTap: controller.toggleFenceList),
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
    final center = _mapCenter;
    // 坐标未就绪时不创建地图（等价于参考项目的 v-if 门控），
    // 避免先渲染默认坐标（北京）再跳到真实位置。
    if (center == null) {
      return const ColoredBox(
        color: Color(0xFFF2F4F8),
        child: Center(child: AppLoadingIndicator()),
      );
    }
    return MapTile(
      isLoading: controller.isLoading.value,
      // 页面提示统一改为从顶部向下弹出的 AppToast，不再用地图浮层展示。
      errMsg: '',
      latitude: center.latitude,
      longitude: center.longitude,
      initialZoom: 12,
      mapController: controller.mapController,
      clusterMarkers: false,
      fitToBounds: true,
      polygons: controller.polygons,
      circles: controller.circles,
      markers: controller.mapMarkers,
      onMapTap: controller.handleMapTap,
      onMapReady: controller.handleMapReady,
    );
  }

  /// 地图中心：没有任何可用坐标时返回 null —— 此时**不创建地图**，
  /// 避免用默认坐标（北京）先渲染出来再跳到真实位置。
  LatLng? get _mapCenter {
    final fence = controller.selectedFence.value;
    if (fence != null) {
      final points = controller.parseArea(fence.area, fence.isCircle);
      if (points.isNotEmpty) return points.first;
    }
    final points = controller.draftPoints;
    if (points.isNotEmpty) return points.first;
    return controller.initialCenter.value ?? controller.devicePosition.value;
  }

  Widget _buildToolbar(BuildContext context) {
    final isCircle = controller.drawingMode.value == 'circle';
    return ReferenceCard(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: controller.isDrawing.value
          ? _buildEditingPanel(context, isCircle)
          : Row(
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
                const SizedBox(width: 10),
                // 绘制按钮改为紧凑小尺寸，避免大号填充按钮在工具栏中显得突兀。
                SizedBox(
                  height: 32,
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: controller.startDrawing,
                    child: const Text(
                      '绘制',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// 编辑/绘制态面板：标题行（含取消）+ 状态提示 + 重置/保存操作，
  /// 分区清晰，避免与上方工具栏的操作混淆。
  Widget _buildEditingPanel(BuildContext context, bool isCircle) {
    final editing = controller.selectedFence.value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.pencil, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                editing ? '正在编辑围栏' : '正在绘制围栏',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            // 新增取消：放弃本次修改并退出编辑态。
            _SmallTextButton(label: '取消', onPressed: controller.cancelDrawing),
          ],
        ),
        const SizedBox(height: 9),
        Container(height: 1, color: AppColors.divider),
        const SizedBox(height: 9),
        Text(
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
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _SmallActionButton(
                label: '重置',
                onPressed: controller.clearDraft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallActionButton(
                label: '保存',
                filled: true,
                onPressed: controller.canFinishDrawing
                    ? () => _save(context)
                    : null,
              ),
            ),
          ],
        ),
      ],
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
    final action = await showAppActionSheet<String>(
      context: context,
      title: fence.name,
      actions: const [
        AppSheetAction<String>(label: '管理设备', value: 'devices'),
        AppSheetAction<String>(label: '编辑', value: 'edit'),
        AppSheetAction<String>(
          label: '删除',
          value: 'delete',
          isDestructive: true,
        ),
      ],
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
      () => Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          // 仅顶部圆角：底部直接贴住屏幕下缘，不产生留白。
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        // SafeArea 放在 Container 内部：背景色延伸到屏幕最底部，消除底部留白。
        child: SafeArea(
          top: false,
          child: SizedBox(
            // 最多半屏：设备较多时列表在内部上下滚动，弹框不再撑得过高。
            height: MediaQuery.sizeOf(context).height * .5,
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
                        children: const {0: Text('已绑定'), 1: Text('未绑定')},
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
                // 开关切换即时生效，不再需要批量按钮；此处仅保留一行操作说明。
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '开关开启表示已绑定，关闭表示未绑定，切换后即时生效',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    final bound = controller.deviceTab.value == 0;
    final devices = bound ? controller.boundDevices : controller.unboundDevices;
    if (devices.isEmpty) {
      return EmptyState(message: bound ? '暂无已绑定设备' : '暂无可绑定设备');
    }
    return ListView.separated(
      itemCount: devices.length,
      // 相邻设备之间用淡灰色横线分割，列表层次更清晰。
      separatorBuilder: (_, _) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0xFFEDEFF3),
      ),
      itemBuilder: (_, index) {
        final device = devices[index];
        final deviceNo = controller.deviceNoOf(device);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
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
              const SizedBox(width: 12),
              // 开关与设备信息分居左右两侧：开=已绑定，关=未绑定，切换即时生效。
              Transform.scale(
                scale: .85,
                child: CupertinoSwitch(
                  // 提交中先显示目标状态，完成后由刷新后的列表接管。
                  value: controller.pendingDeviceNos.contains(deviceNo)
                      ? !bound
                      : bound,
                  onChanged: controller.pendingDeviceNos.contains(deviceNo)
                      ? null
                      : (value) =>
                            controller.setDeviceBound(device, bound: value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _alarmTypeLabels = ['不告警', '出入告警', '出告警', '入告警'];

/// 编辑面板顶部的小号文字按钮（如「取消」）。
class _SmallTextButton extends StatelessWidget {
  const _SmallTextButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    minimumSize: Size.zero,
    onPressed: onPressed,
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
    ),
  );
}

/// 编辑面板底部的小号操作按钮（重置 / 保存），比通用大按钮更协调。
class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: filled
        ? CupertinoButton.filled(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            borderRadius: BorderRadius.circular(10),
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF2F4F8),
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
  );
}

/// 收起态底部的圆形向上箭头：持续上下轻微跳动，引导用户点击展开更多信息。
///
/// 自带 AnimationController（仅在收起态挂载，展开后自动销毁），
/// 不给 GeofenceController 增加额外的生命周期负担。
class _BouncingArrowButton extends StatefulWidget {
  const _BouncingArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BouncingArrowButton> createState() => _BouncingArrowButtonState();
}

class _BouncingArrowButtonState extends State<_BouncingArrowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // 向上 7px 的往复位移：幅度克制，只做引导，不喧宾夺主。
    _offset = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _offset.value), child: child),
      child: GestureDetector(
        onTap: widget.onTap,
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
    );
  }
}
