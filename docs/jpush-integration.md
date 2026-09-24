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
| AppKey（Dart） | `lib/services/push/push_config.dart` | `0ee065e1a4024ce1801fa6d3`（Android / iOS 共用） |
| Channel | `lib/services/push/push_config.dart` | `developer-default` |
| AppKey（Android） | `android/app/build.gradle.kts` → `manifestPlaceholders["JPUSH_APPKEY"]` | 同上 |
| Android Manifest | `android/app/src/main/AndroidManifest.xml` | `JPUSH_APPKEY` / `JPUSH_CHANNEL` meta-data |
| iOS AppKey | 由 Dart 在 `PushService.init()` 里传给 `JPush.setup()` | 同上 |
| iOS APNs 环境 | `PushConfig.iosProduction` | `true`（Release/TestFlight/App Store） |
| iOS 推送能力 | `ios/Runner/Runner.entitlements` + `project.pbxproj` 的 `SystemCapabilities` | `aps-environment = production` |

Android 端 JPush SDK 从 Manifest 的 meta-data 读取 AppKey，因此 Dart 侧传空串
（`PushConfig.setupAppKey`）；iOS 由 Dart 传入。

Channel 不同：插件在 `setup()` 里对两端都调用 `JPushInterface.setChannel(context, channel)`，
所以 Android 运行时以 Dart 的 `PushConfig.channel` 为准，Manifest 的 `JPUSH_CHANNEL`
只是初始值。改渠道号只需改 `push_config.dart` 一处。

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
- 回到前台刷新 RegistrationID 并清零角标；**清角标不受登录态与推送初始化限制**
  （`main()` 启动时与回前台时都会调 `setBadge(0)`，避免 token 过期停在登录页时角标残留）。

### 4.2 收到推送后的行为

1. 从 payload 的 `messageId`、`message_id` 或 `id`（含 `data`、`extra`、`extras`、`notificationExtras` 嵌套）提取业务消息 ID；
2. 清零角标，并标记消息中心需要刷新；
3. 用户点击通知且已登录时切换到消息页（`NavigationService.navigateTo(messagesIndex)`）；
4. 消息页刷新列表，在第一页找到同一 `messageId` 时自动打开详情并标记已读；
5. JPush 的 `msgId` 是通道侧消息 ID，**不作为**业务消息 ID 的兜底。

### 4.3 角标策略

本应用没有服务端同步的全局未读数，列表里的 `status` 只表示单条消息已读状态。
因此主屏幕角标固定为 `0`：

- iOS：启动（`main()`）、回到前台、处理推送事件时都会 `setBadge(0)`；未登录 /
  token 过期时同样清零（插件内部会先直接改 `applicationIconBadgeNumber`）；
- Android：极光角标接口官方仅支持华为机型（`JPushInterface.setBadgeNumber`），
  其余 ROM 的角标跟随通知栏条数，因此在「点击通知」「进入消息页」「一键已读」时
  调用 `clearAllNotifications()`，让角标随通知栏一起消失。

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
- [ ] iOS 角标保持为 0（含未登录 / token 过期停在登录页时）；
- [ ] Android 华为机型：收到推送后角标出现，进入消息页 / 一键已读 / 点击通知后角标与通知栏一起消失。

### 6.1 厂商通道验证（需真机 + 发布签名）

- [ ] 打包证书与各厂商后台登记的指纹一致（否则厂商通道注册失败，极光后台会显示未注册）；
- [ ] **杀进程后**仍能在华为 / 荣耀 / 小米 / OPPO 真机上收到推送（这是厂商通道唯一有效验证）；
- [ ] 极光控制台「推送设置 → 集成设置」已填入各厂商 App Secret / Master Secret；
- [ ] 日志出现厂商注册成功：华为 `get huawei token`、小米 `xiao mi push register success`、
      OPPO `OPush registerID`、荣耀 `get honor token`；
- [ ] release 包验证（debug 不走 R8，无法验证混淆规则是否生效）。

## 7. 待确认事项

1. **包名 / Bundle ID（已确认）**：Android 包名与 iOS Bundle ID 均已统一为 `com.zdiot.app`
   （见 `docs/packaging.md`），极光 AppKey `0ee065e1a4024ce1801fa6d3`（Android / iOS 共用）
   已在极光控制台绑定到该包名。再次换包名时必须先在极光控制台登记新包名，并同步修改
   `lib/services/push/push_config.dart` 与 `android/app/build.gradle.kts` 两处 AppKey，
   否则两端收不到推送。
2. **iOS APNs 证书**：`com.zdiot.app` 的生产环境 APNs 推送证书需已上传到极光控制台
   （旧 Bundle ID 的证书不可复用，需按新 Bundle ID 重新生成 Push 证书 / p8）。
3. **厂商通道（已接入并通过 release 构建验证）**：Android 已接入华为 / 荣耀 / 小米 / OPPO 四家厂商通道。

   **依赖**：`cn.jiguang.sdk.plugin:{huawei,honor,xiaomi,oppo}:6.2.1`（必须与 `jpush_flutter`
   内置的 `cn.jiguang.sdk:jpush:6.2.1` 版本一致，见 `android/app/build.gradle.kts`）。
   华为 HMS（`com.huawei.hms:base:6.13.0.303`）与荣耀（`com.hihonor.mcs:push:10.0.13.305`）
   由极光插件自动传递引入。

   **客户端参数**：`android/app/build.gradle.kts` 的 `manifestPlaceholders` + 厂商 SDK AAR
   自带的 `meta-data`。本工程只在 `AndroidManifest.xml` 声明 `JPUSH_APPKEY` /
   `JPUSH_CHANNEL` 和 `XIAOMI_APPID` / `XIAOMI_APPKEY`（小米需要 `tools:replace` 覆盖，
   原因见下），**华为 / 荣耀 / OPPO 的 meta-data 已由各厂商 AAR 自带，重复声明会触发
   manifest 合并冲突**。已验证的最终落地值（release 打包 manifest）：

   | 厂商 | meta-data | 值 |
   | --- | --- | --- |
   | 极光 | `JPUSH_APPKEY` | `0ee065e1a4024ce1801fa6d3` |
   | 华为 | `com.huawei.hms.client.appid` | `appid=119069041`（AGC 插件自动注入） |
   | 荣耀 | `com.hihonor.push.app_id` | `104591945` |
   | 小米 | `XIAOMI_APPID` / `XIAOMI_APPKEY` | `2882303761520585420` / `5172058551420` |
   | OPPO | `OPPO_APPID` / `OPPO_APPKEY` / `OPPO_APPSECRET` | `OP-37752444` / `OP-be93df…a57f6` / `OP-ec6663…b2eb`（必须带 `OP-` 前缀） |

   > **小米 AAR 的坑**：极光 `xiaomi:6.2.1` AAR 里的值模板是 `"${XIAOMI_APPID}\"`（末尾多一个
   > 反斜杠），占位符替换后 AppID 会变成 `2882303761520585420\`，导致小米通道注册失败。
   > 因此 `AndroidManifest.xml` 用 `tools:replace="android:value"` 覆盖为不含反斜杠的值。

   **华为额外要求**：
   - `android/app/agconnect-services.json`（AGC 下载，`package_name = com.zdiot.app`、
     `app_id = 119069041`）；构建产物中会生成 `agconnect-core.properties` 打进 APK；
   - 根 `android/build.gradle.kts` 引入 `com.huawei.agconnect:agcp:1.9.6.300`（华为仓库
     `https://developer.huawei.com/repo/`），app 模块 `apply(plugin = "com.huawei.agconnect")`；
   - **`gradle/libs.versions.toml` 必须存在且含 `agcp`**：agcp 在 apply 时会访问
     `VersionCatalogsExtension.named("libs")`，缺失会抛 `Catalog named libs doesn't exist`；
   - **`buildscript` classpath 必须显式声明 `com.android.tools.build:gradle:9.0.1`**：agcp
     传递依赖了 AGP 7.5 时代的 `org.gradle:gradle-plugin:7.5.1`，会把旧版
     `BaseAppModuleExtension` 带进 Kotlin DSL 脚本编译类路径，导致 `android {}` 的
     `namespace` / `compileSdk` 全部 unresolved。用当前 AGP 版本压过即可。

   **混淆**：release 会执行 R8，`android/app/proguard-rules.pro` 保留了极光与四家厂商 SDK
   的类（它们大量使用反射和 Manifest 组件，被裁剪后通道会**静默**注册失败）。已在
   `build.gradle.kts` 的 `release` 中通过 `proguardFiles` 引用。

   **其余**：
   - 各厂商 App Secret / Client Secret / Master Secret 等**仅填在极光控制台**
     「消息推送 → 推送设置 → 集成设置」，不写入客户端代码；
   - **签名一致**：华为/荣耀/小米/OPPO 均校验「包名 + 签名指纹」，打包证书必须是各厂商后台
     登记过的同一本证书（见 `docs/packaging.md` 2.1），否则厂商通道注册失败。

   验证：杀进程后推送能收到，日志出现各厂商注册成功（华为 `get huawei token`、
   小米 `xiao mi push register success`、OPPO `OPush registerID`、荣耀 `get honor token`）。
