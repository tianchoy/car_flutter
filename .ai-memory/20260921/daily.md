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
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。

## [当前] - UI 优化: 统一我的车辆列表副标题布局

- **文件**: lib/views/account/vehicles/list/vehicle_list_view.dart
- **决策**: 将原先可能自然换行的拼接 subtitle 改为固定两行元数据：车牌、设备号（缺失时显示明确占位）；标题单行省略，元数据单行省略，确保每张车辆卡片高度一致、字段排列整齐。
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。

## [当前] - Bug 修复: 统一车辆详情页无数据占位符

- **文件**: lib/views/account/vehicles/detail/vehicle_detail_view.dart、lib/views/account/vehicles/detail/vehicle_detail_controller.dart
- **决策**: 车辆详情字段统一将 null、空字符串和后端返回的 -- 显示为 -；附加信息查询方法默认 fallback 改为 -，更新时间不再显示 --。
- **验证**: flutter analyze 通过（仅保留既有 info）；flutter test 全量通过（27 个测试）。

## [当前] - 功能实现: 优化首页、设备状态、地图面板与消息展示

- **文件**: lib/views/home/home_view.dart、lib/views/device/detail/detail_view.dart、lib/views/vehicle/playback/playback_controller.dart、lib/views/geofence/geofence_controller.dart、lib/models/message/msg_model.dart、lib/views/messages/messages_view.dart、lib/views/messages/message_detail_dialog.dart
- **决策**: 放大首页右上角设备列表/添加按钮；将首页轨迹圆环改为紧凑指标卡；设备详情状态改为左图标右数值；轨迹回放和地理围栏面板默认展开；消息标题和正文分别使用后端 title 与 content。
- **验证**: 目标文件静态诊断无 error/warning；flutter test 全量通过（27 个测试）；flutter analyze 仅报告既有 6 条 info。

## [当前] - UI 优化: 简化设备详情状态横排

- **文件**: lib/views/device/detail/detail_view.dart
- **决策**: 移除每个状态数值的独立背景框和内边距，保留四项横向自适应分配空间的左图标右数值布局。
- **验证**: flutter analyze lib/views/device/detail/detail_view.dart 通过；目标文件无 error/warning。

## [当前] - UI 优化: 设备状态改为单行图标与标签数值布局

- **文件**: lib/views/device/detail/detail_view.dart
- **决策**: 设备状态四项保持同一行，每项左侧显示图标，右侧上下显示标签和数值；ID 模块图标缩小至 18。
- **验证**: flutter analyze 目标文件通过；git diff --check 通过；目标文件无 error/warning。

## [当前] - UI 优化: 首页信息项与全部设备入口调整

- **文件**: lib/views/home/home_view.dart、lib/views/device/list/device_list_view.dart
- **决策**: 首页电量、电压等四项信息统一为左图标、右侧标签和数值上下排列；全部设备页面移除顶部添加按钮及其跳转功能，仅保留地图/列表切换。
- **验证**: 三个目标文件静态分析通过；flutter test 全量通过（27 个测试）。

## [当前] - 功能实现: 轨迹回放增加可拖动进度条并优化底部面板

- **文件**: lib/views/vehicle/playback/playback_controller.dart、lib/views/vehicle/playback/playback_view.dart
- **决策**: 进度以轨迹点序列归一化计算，拖动时暂停当前动画并即时更新车标、已播/未播路线和时间/速度信息；松手后若拖动前正在播放则从定位点继续播放。底部面板分层展示时间范围、回放进度、播放控制、倍速和轨迹指标。
- **验证**: dart format 通过；git diff --check 通过；flutter analyze 目标文件通过；flutter test 全量通过（30 个测试）。

## [当前] - UI 优化: 压缩轨迹回放底部面板

- **文件**: lib/views/vehicle/playback/playback_view.dart
- **决策**: 移除进度条两侧的当前时间、结束时间和说明文字，进度块改为单行“进度 + 滑块 + 百分比”；隐藏面板标题状态行，时间范围不显示秒；播放按钮、倍速滑块和倍速标签压缩为同一行；速度与里程保留为紧凑指标行，减少地图路线和车标遮挡。
- **验证**: dart format 通过；git diff --check 通过；flutter analyze 目标文件通过；flutter test 全量通过（30 个测试）。
## [当前] - Bug 修复: 结束时间选择器禁止超过当前时间

- **文件**: lib/widgets/reference_date_time_picker.dart、third_party/flutter_cupertino_datetime_picker/lib/src/widget/datetime_picker_widget.dart、pubspec.yaml、pubspec.lock、analysis_options.yaml
- **决策**: 默认非未来模式将最大时间统一截断到打开选择器时的当前秒；确认结果再次做上下限保护；本地依赖修正最大分钟和最大秒边界错误，避免滚轮放行当前时间之后的几秒。设备分享的 `allowFuture: true` 保持原有未来日期能力。
- **验证**: dart format 通过；flutter pub get 成功；目标文件静态检查无 error/warning；项目级 `flutter analyze` 仅剩原有 6 条 info；git diff --check 通过。

## [当前] - Bug 修复: 结束时间选择器初始值对齐打开时刻

- **文件**: lib/views/vehicle/mileage/mileage_controller.dart、lib/views/vehicle/stop_record/stop_record_controller.dart、lib/views/vehicle/playback/playback_controller.dart
- **决策**: 秒列“多出的秒”是页面加载时记录的旧 endTime 与选择器打开时刻（真正上限）之间的过去秒，并非未来时间；将结束时间选择器打开时的初始值改为打开那一刻的 DateTime.now()，使秒滚轮最后一项就是当前秒。开始时间仍用已存值初始化。
- **验证**: dart format 通过；flutter analyze 三个目标文件无问题。

## [当前] - UI 修复: 统一车辆跟踪页与首页地图车标尺寸

- **文件**: lib/views/vehicle/tracking/tracking_controller.dart
- **决策**: 将车辆跟踪页地图车标图片由 36×36 调整为 32×32，与首页地图车标保持一致；保留跟踪页 Marker 44×48 布局区域，避免影响定位和旋转。
- **验证**: dart format 通过；flutter analyze 目标文件无问题；git diff --check 通过。

## [当前] - Bug 修复: 设备添加页设备号必须为纯数字

- **文件**: lib/views/device/add/add_device_controller.dart
- **决策**: 设备 ID 只能为纯数字；提交前校验非纯数字直接提示“设备 ID 只能为数字”并拦截提交；扫码回填同样执行该校验；15/11 位仍按 Web 端规则规整为 12 位；移除提交时打印设备号的调试输出。
- **验证**: dart format 通过；flutter analyze 目标文件无问题。

## [当前] - Bug 修复: 首页切换设备后地图立刻居中新车标

- **文件**: lib/views/home/home_controller.dart
- **决策**: 根因是 selectDevice 从不调用 mapController.move，且 MapTile 的 initialCenter 只在首次构建生效；切换设备前 devicePosition 仍是旧设备坐标。修复为切换时先用 DeviceModel 自带经纬度（GCJ-02 转换）更新 deviceRawPosition/devicePosition 并立即 move，接口返回后按 generation 再居中一次；MapController 未挂载时下一帧补移动；已有坐标时不把状态置为 loading。
- **验证**: dart format 通过；flutter analyze 首页控制器与视图无问题；git diff --check 通过。

## [当前] - Bug 修复: 轨迹回放气泡速度在未播放/结束时归零

- **文件**: lib/views/vehicle/playback/playback_controller.dart、lib/views/vehicle/playback/playback_view.dart
- **决策**: 气泡速度改为读取 currentSpeed（展示速度）；轨迹加载后与重置到起点时置 0，播放中每帧同步当前片段目标点速度，回放结束后置 0；拖动进度条仍显示所定位点的速度。
- **验证**: dart format 通过；flutter analyze 两个目标文件无问题；git diff --check 通过。

## [当前] - UI 修复: 轨迹回放加载后自适应缩放使整条轨迹落在可视区

- **文件**: lib/views/vehicle/playback/playback_controller.dart
- **决策**: _fitTrack 按未被顶部浮动标题条（top 72）与底部播放抽屉（展开 240 / 收起 88）遮挡的区域计算 CameraFit；单点时直接 move 到 zoom 15；地图未挂载时下一帧重试，避免 fit 被静默吞掉。
- **验证**: dart format 通过；flutter analyze 目标文件无问题；git diff --check 通过。

## [当前] - UI 修复: 车标气泡不被顶部标题条遮挡且间距与首页一致

- **文件**: lib/views/vehicle/playback/playback_view.dart、lib/views/vehicle/playback/playback_controller.dart、lib/views/vehicle/tracking/tracking_view.dart
- **决策**: 气泡 Marker 改为内容底部对齐并上抬「车标半高 + 3」，与首页气泡箭头尖端到车标的 3px 间距一致（回放页车标 32 半高 16 → 19；跟踪页车标 24 半高 12 → 15）；回放页 _fitTrack 顶部 padding 由 72 提到 130，预留标题条与气泡空间。
- **验证**: dart format 通过；flutter analyze 三个目标文件无问题；git diff --check 通过。
