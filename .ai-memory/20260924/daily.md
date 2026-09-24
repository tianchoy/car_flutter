## [当前] - 功能实现: 登录 NEED_SET_PASSWORD 跳转设置密码页

- **文件**: lib/models/api_response.dart、lib/app/routes/routes.dart、lib/app/routes/route_arguments.dart、lib/app/routes/router_instance.dart、lib/views/login/login_controller.dart、lib/views/account/set_password/（新增 controller/repository/view/binding）、test/need_set_password_signal_test.dart（新增）
- **决策**: 参照 Web 端 carConnectInternet/pages/login/set-password.uvue：标志在 msg 文本（NEED_SET_PASSWORD:xxx），触发场景是短信验证码登录；补齐密码复用注册接口 /auth/register（password+confirmPassword+phonenumber+smsCode），成功后接口直接返回 access_token，按 Web 端行为直接完成登录（无 token 才回登录页）。判定做三种形态兼容（msg 文本 / data 字段 / 顶层字段，按去分隔符文本匹配）。密码登录分支命中时提示改用验证码登录（补设密码需要验证码）。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 40 个用例全部通过（含新增 NEED_SET_PASSWORD 判定回归测试）。

## [当前] - Bug 修复: 登录/注册/忘记密码/设置密码与 Web 端对齐

- **文件**: lib/models/api_response.dart、lib/views/login/login_controller.dart、lib/views/login/login_view.dart、lib/views/account/forgot_password/forgot_password_repository.dart、lib/views/account/set_password/set_password_view.dart、lib/views/account/set_password/set_password_controller.dart、test/need_set_password_signal_test.dart
- **决策**: 按 carConnectInternet 基线修 5 处：① 忘记密码短信 scene 由 forgotPassword 改为 forgot（与 request.uts 一致）；② 新增 NEED_REGISTER 标志支持，与 NEED_SET_PASSWORD 共用设置密码页（Web login.uvue 同语义），判定函数参数化并新增 requiresPasswordSetup；③ 短信登录提交校验改为手机号正则 + 6 位验证码；④ 发码按钮由「长度>=11」改为手机号正则；⑤ 新增 setLoginMode，切回密码登录时清空验证码并停止倒计时（与 Web toggleLoginMode 一致）。设置密码页副标题改为「请设置登录密码后继续。」以同时覆盖补密码与首次注册两种入口。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 41 个用例通过（回归测试扩展覆盖 NEED_REGISTER 与互不误判）。

## [当前] - 性能修复: 首次安装后登录页输入卡顿

- **文件**: lib/app/app.dart、lib/widgets/reference_ui.dart、lib/views/login/login_view.dart、lib/services/post_consent_bootstrap.dart、lib/views/account/privacy_consent/privacy_consent_controller.dart
- **决策**: 排查发现三处与「重新安装后首次输入账号密码卡顿」相关的代码因素：① 主题显式指定系统字体族 PingFang SC，iOS 需按名解析字体族并在首次输入聚焦时按新字号/字重组合查找字形，改为不指定（iOS 默认即 PingFang SC，视觉不变）；② 输入框未关闭系统联想/自动更正/自动填充提示，首次聚焦会触发系统侧一次性初始化，ReferenceInput 新增 disableInputAssist 并在登录页四个输入框启用；③ 首次同意隐私政策后 clearBadge 被 unawaited 丢到事件循环，与用户紧接着在登录页首次输入重叠，改为 PostConsentBootstrap.run(awaitSdkInitialization: true)，把该开销留在同意页 loading 内（冷启动 main 路径保持异步，不拖慢首帧）。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 41 个用例通过；git diff --check 通过。

## [当前] - Bug 修复: 校验提示弹出导致输入焦点跳到别的输入框

- **文件**: lib/widgets/reference_ui.dart、test/reference_input_focus_test.dart（新增）
- **决策**: 根因是 ReferenceInput 在 errorText 空/非空时返回不同层级的 widget（CupertinoTextField 与 Column[CupertinoTextField, 提示]），校验提示一出现输入框 Element 即被重建，焦点丢失并回落到页面第一个输入框（截图中修改密码页表现为焦点跳回旧密码框）。修复为结构恒定：始终返回 Column[输入框, 提示/占位]，输入框固定为第 0 个子节点。影响面覆盖所有使用 ReferenceInput + errorText 的页面（修改密码 3 个字段、添加设备设备号、指令中心参数输入）。
- **其他页面核查**: ReferenceTextField 无 errorText；车辆详情编辑字段、电子围栏保存弹框（autofocus）结构稳定；注册/忘记密码/设置密码用 toast 提示，不涉及输入框结构变化，均无同类问题。
- **验证**: 新增 widget 回归测试并做反向验证——临时还原旧结构时该测试在第 52 行断言失败（证明可捕获此 bug），恢复修复后通过；flutter test 全量 42 个用例通过；flutter analyze 项目级仅剩既有 5 条 info；git diff --check 通过。

## [当前] - Bug 修复: 登录页输入控制器被提前销毁（红屏/无法输入）+ 移除重复规则说明

- **文件**: lib/views/account/change_password/change_password_view.dart、lib/views/account/register/register_view.dart、lib/views/account/register/register_controller.dart、lib/app/routes/router_instance.dart、lib/views/login/login_controller.dart
- **决策**: ① 修改密码页移除与红色错误提示重复的固定规则说明（规则只在输入不合规时以红字展示）。② 登录页「A TextEditingController was used after being disposed」根因是注册页用 Get.offNamed(Routes.login) 在栈顶再压一个登录页，形成两个登录页；第二次执行 LoginBindings 时旧 LoginController 被替换/onClose，其 TextEditingController 被 dispose，而旧登录页 widget 仍在栈上，输入时写 controller 抛错（聚焦成功但打不进字），重建时读 controller 直接红屏。修复：注册页两处跳转改 offAllNamed 清栈；Routes.login 加 preventDuplicates: true；LoginController.onClose 不再 dispose 输入控制器（TextEditingController 无外部资源，监听方 widget 销毁时自行移除监听，交给 GC）。
- **其他页面核查**: 注册/忘记密码/设置密码/添加设备/修改密码等表单页的跳转均为 offAllNamed 或单次 push，未发现同类重复压栈；同类模式建议后续按需统一加 preventDuplicates。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 42 个用例通过；git diff --check 通过。

## [当前] - UI 调整: 未读角标左边缘固定、椭圆向右延伸

- **文件**: lib/widgets/bottom_nav_bar.dart
- **决策**: 角标定位由「右边缘对齐（right: -15）」改为「左边缘定位」：新增 _badgeLeftOverlap=1 与 _badgeLeft=(iOS 25 / Android 22)-1 的静态计算，角标左边缘固定在图标右上角内侧 1px；个位数时宽高 16 且 StadiumBorder → 正圆，两位数 / 99+ 宽度撑开 → 椭圆胶囊，宽度增加只向右延伸，左侧位置恒定。因图标宽度随 CupertinoTabBar.iconSize 变化（iOS 25、Android 22），锚点按平台同步计算。
- **验证**: dart format 通过；flutter analyze 目标文件无问题；flutter test 全量 42 个用例通过；git diff --check 通过。

## [当前] - UI 调整: 角标按平台设定尺寸并让数字居中

- **文件**: lib/widgets/bottom_nav_bar.dart
- **决策**: _badgeFontSize / _badgeSize 由固定值改为按平台：iOS 13 / 19，Android 12 / 17（与 iconSize iOS 25 / Android 22 配套）；数字行高由 1.2 改为 1（行框不再带上下留白），配合 Container 的 Alignment.center 使数字落在角标几何中心。
- **验证**: dart format 通过；flutter analyze 目标文件无问题；flutter test 全量 42 个用例通过。

## [当前] - Bug 修复: 设备分享「查看被分享者」弹窗只显示黑色遮罩

- **文件**: lib/views/device/share/device_share_controller.dart
- **决策**: 根因是 _ShareesDialog 用 CupertinoAlertDialog 承载 ListView（可滚动组件），弹框 content 无法测量其尺寸 → 内容高度算成 0，只剩遮罩（项目内 geofence_view 已有同类经验注释）。改为固定宽度 280 + maxHeight 60
## [当前] - Bug 修复: 设备分享「查看被分享者」弹窗只显示黑色遮罩

- **文件**: lib/views/device/share/device_share_controller.dart
- **决策**: 根因是 _ShareesDialog 用 CupertinoAlertDialog 承载 ListView（可滚动组件），弹框 content 无法测量其尺寸，内容高度算成 0，只剩遮罩（项目内 geofence_view 已有同类经验注释）。改为固定宽度 280 + 限高（屏高 60%）的自定义面板：标题 + 分隔线 + 限高滚动列表（ListView.separated，shrinkWrap）+ 关闭按钮；分隔线自绘 _DialogDivider（Cupertino 库无 Material Divider）。
- **其他弹窗核查**: app_links 客服、app_confirm_dialog、geofence 保存围栏、message_detail_dialog、commands 指令详情均为 SingleChildScrollView 或纯文本（可测量），无同类问题。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 42 个用例通过；git diff --check 通过。

## [当前] - 功能调整: 设备分享列表直接展示被分享者手机号并移除查看弹窗

- **文件**: lib/views/device/share/device_share_view.dart、lib/views/device/share/device_share_controller.dart
- **决策**: 在分享卡片「角色」行下方新增「手机号」行（targetPhoneMasked），不再需要「查看被分享者」弹窗；删除该按钮、controller 的 sharees 状态与 showSharees 方法、_ShareesDialog 与 _DialogDivider 组件，以及随之无用的 reference_ui 导入；撤销操作改为仅在 status=active 时渲染，非生效中不再保留空操作行。
- **验证**: dart format 通过；flutter analyze 项目级仅剩既有 5 条 info；flutter test 全量 42 个用例通过；git diff --check 通过。
