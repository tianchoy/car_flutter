# 极光推送（JPush）接入说明

Flutter 工程（`car_flutter`）的推送实现，行为对齐 uni-app X 源工程 `carConnectInternet`
的 `services/push.uts` / `services/push-binding.uts` / `services/app-startup.uts`。

## 1. 运行路径

| 平台 | provider | 设备标识 | 获取方式 | 服务端发送通道 |
| --- | --- | --- | --- | --- |
| Android | `jpush`（`jpush_flutter 3.5.8`） | JPush `RegistrationID` | `JPush.getRegistrationID()` | JPush（厂商通道由极光后台选择） |
| iOS | `jpush`（`jpush_flutter 3.5.8`） | JPush `RegistrationID` | `JPush.getRegistrationID()` | JPush / APNs |

服务端必须通过该 `RegistrationID` 经 JPush 下发，不能当作其他推送平台的设备标识。

## 2. 配置位置

| 项 | 位置 | 值 |
| --- | --- | --- |
| AppKey（Dart） | `lib/services/push/push_config.dart` | `a53c28d734057573f67e16f7` |
| Channel | `lib/services/push/push_config.dart` | `developer-default` |
| AppKey（Android） | `android/app/build.gradle.kts` → `manifestPlaceholders["JPUSH_APPKEY"]` | 同上 |
| Android Manifest | `android/app/src/main/AndroidManifest.xml` | `JPUSH_APPKEY` / `JPUSH_CHANNEL` meta-data |
| iOS AppKey | 由 Dart 在 `PushService.init()` 里传给 `JPush.setup()` | 同上 |
| iOS APNs 环境 | `PushConfig.iosProduction` | `true`（Release/TestFlight/App Store） |
| iOS 推送能力 | `ios/Runner/Runner.entitlements` + `project.pbxproj` 的 `SystemCapabilities` | `aps-environment = production` |

Android 端 JPush SDK 从 Manifest 的 meta-data 读取 AppKey，因此 Dart 侧传空串
（`PushConfig.setupAppKey`），避免两处配置不一致；iOS 由 Dart 传入。

## 3. 代码结构

| 文件 | 职责 |
| --- | --- |
| `lib/services/push/push_config.dart` | AppKey、渠道、APNs 环境、重试策略 |
| `lib/services/push/push_service.dart` | JPush 初始化、RegistrationID 缓存与重试、事件归一化、角标清零、待处理消息落盘 |
| `lib/services/push/push_binding_service.dart` | `POST /app/push/bind` 绑定、`POST /app/push/unbind` 解绑 |
| `lib/services/push/push_bootstrap.dart` | 登录后延后初始化、回到前台刷新 |

## 4. 前端行为

### 4.1 初始化与 RegistrationID

- 推送**不在** `main()` 中初始化，避免未登录时注册设备；
- 登录成功跳到首页后延后 1.2s 初始化；已登录用户冷启动时由 `HomeController` 兜底触发；
- 注册事件回调后再 `setup`，保证 SDK 缓存的冷启动点击事件能被派发；
- RegistrationID 为空时每 3 秒重试，最多 5 次；
- RegistrationID 写入 `SessionKeys.pushRegistrationId`，退出登录时保留（它是设备标识，不是账号数据）；
- 回到前台刷新 RegistrationID 并清零角标。

### 4.2 收到推送后的行为

1. 从 payload 的 `messageId`、`message_id` 或 `id`（含 `data`、`extra`、`extras`、`notificationExtras` 嵌套）提取业务消息 ID；
2. 清零角标，并标记消息中心需要刷新；
3. 用户点击通知且已登录时切换到消息页（`NavigationService.navigateTo(messagesIndex)`）；
4. 消息页刷新列表，在第一页找到同一 `messageId` 时自动打开详情并标记已读；
5. JPush 的 `msgId` 是通道侧消息 ID，**不作为**业务消息 ID 的兜底。

### 4.3 iOS 角标策略

本应用没有服务端同步的全局未读数，列表里的 `status` 只表示单条消息已读状态。
因此 iOS 主屏幕角标固定为 `0`：启动、回到前台、处理推送事件时都会 `setBadge(0)`。

后端下发 iOS 通知时必须省略 `aps.badge` 或显式发 `0`。

## 5. 后端接口

`Authorization: Bearer <业务登录 token>`，`clientId: 428a8310cd442757ae699df5d894f051`
（`AppConfig.clientId`，由 `HttpService` 统一注入请求头）。

### 5.1 绑定

```http
POST /app/push/bind
```

```json
{
  "registrationId": "<jpush-registration-id>",
  "platform": "android",
  "deviceName": "Xiaomi 14",
  "appVersion": "1.0.5"
}
```

- `platform` 仅为 `android` 或 `ios`，后端从 token 解析用户 ID，前端不传 `userId`；
- 同一 token + RegistrationID 组合在当前运行期内只成功绑定一次，失败不阻塞登录与跳转；
- 前端不调用 JPush `setAlias`，别名由后端负责设置/补偿。

### 5.2 解绑

退出登录时先调用 `POST /app/push/unbind?registrationId=...`（需要业务 token，
必须在清理本地会话之前发出），失败仍继续退出流程。

## 6. 真机验证清单

- [ ] 完整原生构建（不能用热重载验证推送）；
- [ ] 最终包名 / Bundle ID 与极光控制台登记的一致；
- [ ] Android 13+ 已授予通知权限；
- [ ] 日志出现「JPush RegistrationID 已就绪」，并成功调用 `/app/push/bind`；
- [ ] 极光控制台按 RegistrationID 发测试：前台接收、后台系统通知、杀进程冷启动、点击进入消息中心；
- [ ] payload 带有效 `messageId`，验证消息中心刷新与详情自动打开；
- [ ] iOS 角标保持为 0。

## 7. 待确认事项

1. **包名 / Bundle ID（已确认）**：Android 包名与 iOS Bundle ID 均为
   `uni.app.UNI662B0B4`（见 `docs/packaging.md`），与极光 AppKey
   `a53c28d734057573f67e16f7` 在极光控制台绑定。若更换包名，必须先在极光控制台登记，否则两端收不到推送。
2. **iOS APNs 证书**：`uni.app.UNI662B0B4` 的生产环境 APNs 推送证书需已上传到极光控制台。
3. **厂商通道**：源工程 Android 启用了华为厂商通道（`jg-jpush-u-huawei`），本 Flutter 工程
   只接入了 JPush 核心 SDK，未接入华为/小米/OPPO/vivo 等厂商通道；如需提升离线送达率，
   需在 `android/app/build.gradle.kts` 增加对应厂商依赖并在极光控制台配置。
