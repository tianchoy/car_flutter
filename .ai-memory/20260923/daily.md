
## [当前] - Bug 修复: 设备详情油电指令弹框 iOS 卡死

- **文件**: lib/views/device/detail/detail_view.dart
- **决策**: 根因是 CupertinoAlertDialog 的 content 为自适应测量的可滚动区域，内嵌 CupertinoTextField 后 iOS 键盘弹起会与键盘避让反复相互触发布局，导致整屏卡死；同时弹框用的是 Get.context（根 Navigator）。改为用页面自身 context + 自定义固定宽度、尺寸确定、自行处理键盘避让的 _PowerCommandDialog 面板，并关闭密码框联想/自动更正。
- **验证**: dart format 通过；flutter analyze 目标文件无问题；git diff --check 通过。

## [当前] - Bug 修复: 油电指令弹框移除内嵌输入框

- **文件**: lib/views/device/detail/detail_view.dart
- **决策**: 自定义面板在真机（尤其重新打包首次运行）仍偶发卡死，按用户要求去掉弹框内嵌密码输入框；改为 CupertinoAlertDialog 纯提示「确定恢复/断开车辆油电吗？」+ 取消/确定，与项目其他确认框一致；删除 _PowerCommandDialog；指令密码沿用控制器默认空字符串。
- **验证**: dart format 通过；flutter analyze 详情页与控制器无问题；git diff --check 通过。

## [当前] - 重构: 抽取统一确认弹框组件 showAppConfirmDialog

- **文件**: lib/widgets/app_confirm_dialog.dart（新增）；lib/views/device/detail/detail_view.dart、lib/views/home/home_view.dart、lib/views/profile/profile_view.dart、lib/views/device/list/device_list_controller.dart、lib/views/geofence/geofence_view.dart、lib/views/device/commands/commands_view.dart
- **决策**: 各页手写 CupertinoAlertDialog 导致细节不一致（content 有的包 Padding(top:12)、有的没有，标题与内容贴太近）。统一组件固定标题与内容 12px 间距，取消返回 false、确认返回 true、遮罩关闭返回 null，危险操作用 isDestructive 显示红色；替换 6 处确认弹框（油电、删除设备、退出登录、解绑设备、删除围栏、确认下发指令）。
- **验证**: dart format 通过；7 个目标文件 flutter analyze 无问题；项目级 flutter analyze 仅剩既有 5 条 info；git diff --check 通过。
