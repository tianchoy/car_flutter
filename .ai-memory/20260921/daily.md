session-id: 20260921-0901

## [09:01] - 功能实现: 优化车辆跟踪、地理围栏与消息页面交互

- **文件**: lib/views/vehicle/tracking/tracking_view.dart、lib/views/vehicle/tracking/tracking_controller.dart、lib/views/geofence/geofence_view.dart、lib/views/geofence/geofence_controller.dart、lib/views/messages/messages_view.dart、test/geofence_controller_test.dart
- **决策**: 跟踪轮询周期与设备 5 秒上报节奏一致；新围栏按“圆形围栏N”或“多边形围栏N”生成未占用默认名称。
- **验证**: flutter analyze 通过；flutter test 全量通过（27 秒）。

## [09:01] - Bug 修复: 恢复围栏保存弹框展示

- **文件**: lib/views/geofence/geofence_view.dart
- **决策**: 使用固定高度的两行双列单选组件，替代 CupertinoAlertDialog 内无法稳定测量高度的 GridView。
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。

## [当前] - 功能实现: 统一地图车标气泡箭头

- **文件**: lib/widgets/map_marker_bubble.dart、lib/views/home/home_view.dart、lib/views/device/list/device_list_view.dart、lib/views/vehicle/tracking/tracking_view.dart
- **决策**: 抽取公共 MapBubbleTail，首页、设备列表和车辆跟踪页的车标气泡统一在底部增加向下小箭头，指向车标；设备详情、地理围栏、轨迹播放无车标气泡，无需改动。
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。

## [当前] - Bug 修复: 消除地图气泡箭头与主体间隙

- **文件**: lib/views/home/home_view.dart、lib/views/device/list/device_list_view.dart
- **决策**: 删除首页和设备列表气泡主体与 MapBubbleTail 之间多余的 3px 间距；公共箭头仍向上重叠主体底边，与车辆跟踪地图保持一致。
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。
