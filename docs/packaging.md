# 打包配置说明（Android / iOS）

本说明对应 `car_flutter` 工程的发布打包配置，数值取自 uni-app X 源工程的离线打包项目
（`car` 安卓端、`car-ios` iOS 端），保证与线上包一致、可覆盖安装。

## 1. 基础信息（两端统一）

| 项 | 值 |
| --- | --- |
| 应用名称 | 中导物联 |
| Android 包名 / iOS Bundle ID | `com.zdiot.app` |
| 版本号 | `1.0.5` |
| 构建号 | `105` |
| 版本来源 | `pubspec.yaml` 的 `version: 1.0.5+105`（同时驱动 Android `versionName/versionCode` 与 iOS `CFBundleShortVersionString/CFBundleVersion`） |

> 改版本号只需改 `pubspec.yaml` 一处；`flutter build` 会自动同步到原生工程。

## 2. Android

### 2.1 签名（发布证书）

证书与 uni-app X 安卓离线工程 `car/signing.properties` 完全一致：

| 项 | 值 |
| --- | --- |
| Keystore | `/Users/xyhc/Documents/app-signing/zdiot.p12`（与 `zdiot.jks` 同源，PKCS12 格式） |
| 别名 (keyAlias) | `zdiot` |
| 口令 (storePassword / keyPassword) | `871202` |
| 证书指纹 SHA1 | `7C:C7:1E:ED:FF:9C:A5:E0:F0:E8:D7:52:1B:00:43:FA:97:19:93:46` |
| 证书指纹 SHA256 | `2C:D9:42:AC:6C:AF:12:D7:5E:CC:DE:5F:0F:9F:CE:90:B9:D5:F2:65:22:33:94:24:0C:84:E0:90:C6:57:0F:8E` |

配置读取逻辑：`android/key.properties`（已被 `android/.gitignore` 忽略，禁止提交）→
`android/app/build.gradle.kts` 的 `signingConfigs.release`。

`android/key.properties` 内容（绝对路径指向仓库外的签名目录，单一可信源）：

```properties
storeFile=/Users/xyhc/Documents/app-signing/zdiot.p12
storePassword=871202
keyAlias=zdiot
keyPassword=871202
storeType=PKCS12
```

> 缺省 `key.properties` 时回退到 debug 签名，保证无证书环境也能编译；但发布必须用上面的正式证书。

### 2.2 构建命令

```bash
# 正式 APK（已验证可编译）
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk

# 如需 Google Play / 国内应用市场 AAB
flutter build appbundle --release
```

### 2.3 编译参数

`android/app/build.gradle.kts`：

| 参数 | 值 | 说明 |
| --- | --- | --- |
| `namespace` / `applicationId` | `com.zdiot.app` | 与极光推送 AppKey 绑定 |
| `minSdk` | `24` | 与源工程一致 |
| `targetSdk` | `36` | 与源工程一致 |
| `compileSdk` | `37` | `permission_handler` 要求 ≥37（AGP 9.0 会提示推荐 36，但可正常编译） |

### 2.4 极光推送与厂商通道占位符

`android/app/build.gradle.kts` 的 `manifestPlaceholders`：

- 极光核心：`JPUSH_PKGNAME` = applicationId（自动跟随新包名）、
  `JPUSH_APPKEY` = `0ee065e1a4024ce1801fa6d3`（需与 `push_config.dart` 的 `appKey` 一致）、
  `JPUSH_CHANNEL` = `developer-default`；
- 华为：`HUAWEI_APPID` = `119069041`（与 `android/app/agconnect-services.json` 的 `app_id` 一致）；
- 荣耀：`HONOR_APPID` = `104591945`；
- 小米：`XIAOMI_APPID` = `2882303761520585420`、`XIAOMI_APPKEY` = `5172058551420`；
- OPPO：`OPPO_APPID` / `OPPO_APPKEY` / `OPPO_APPSECRET`（三个值都必须带 `OP-` 前缀）。

`AndroidManifest.xml` 只声明 `JPUSH_APPKEY` / `JPUSH_CHANNEL` 与 `XIAOMI_APPID` / `XIAOMI_APPKEY`；
华为 / 荣耀 / OPPO 的 meta-data 由各厂商 SDK AAR 自带（值取自上面的占位符），重复声明会触发
manifest 合并冲突。小米需要 `tools:replace` 是因为极光 `xiaomi:6.2.1` AAR 的模板值末尾多一个
反斜杠，不覆盖会导致 AppID 变成 `2882303761520585420\` 而注册失败。

厂商 SDK 依赖：`cn.jiguang.sdk.plugin:{huawei,honor,xiaomi,oppo}:6.2.1`（与 `jpush:6.2.1` 对齐）。

### 2.5 混淆（release 走 R8）

release 构建会执行 `minifyReleaseWithR8`，`android/app/proguard-rules.pro` 保留极光与
华为 / 荣耀 / 小米 / OPPO 厂商 SDK 的类（它们依赖反射与 Manifest 组件，被裁剪后通道会**静默**
注册失败）。该文件在 `android/app/build.gradle.kts` 的 `release` 中通过 `proguardFiles` 引用。
新增厂商通道或升级极光 SDK 时，需同步检查该文件。

华为厂商通道额外要求：

- `android/app/agconnect-services.json`（AGC 下载，`package_name = com.zdiot.app`、`app_id = 119069041`）；
- 根 `android/build.gradle.kts` 引入 `com.huawei.agconnect:agcp:1.9.6.300`（华为仓库），
  app 模块 `apply(plugin = "com.huawei.agconnect")`；
- `android/gradle/libs.versions.toml` 必须存在且含 `agcp`（agcp 会访问名为 `libs` 的
  Version Catalog，缺失会抛 `Catalog named libs doesn't exist`）；
- 根 `buildscript` 需显式声明 `com.android.tools.build:gradle:9.0.1`，压过 agcp 传递依赖的
  AGP 7.5 时代坐标，否则 `android {}` 会解析为旧 `BaseAppModuleExtension` 导致脚本编译失败。

> 华为/荣耀/小米/OPPO 均校验「包名 + 签名证书指纹」，打包必须使用各厂商后台登记过的**同一本证书**
> （见 2.1 的 SHA256），否则厂商通道注册失败。

## 3. iOS

### 3.1 签名

| 项 | 值 |
| --- | --- |
| Bundle ID | `com.zdiot.app` |
| Team | `4JXH4CSXJ2` |
| 签名方式 | Automatic（Xcode 自动管理证书与描述文件） |
| Push 能力 | 已在 `project.pbxproj` 的 `SystemCapabilities` 开启 `com.apple.Push` |
| 推送权限 | `ios/Runner/Runner.entitlements`：`aps-environment = production` |

> 打包前需在 Xcode 中登录开发者账号（团队 `4JXH4CSXJ2`）。描述文件走 Automatic 即可，
> 无需手动下载 `.mobileprovision`。

### 3.2 后台模式与隐私

`ios/Runner/Info.plist` 已补充：

- `UIBackgroundModes`：`location`、`remote-notification`（保证后台定位与推送及时到达）
- `NSUserNotificationsUsageDescription`：`需要您的同意，才能使用推送功能`
- `CFBundleDisplayName` / `CFBundleName`：`中导物联`

### 3.3 导出配置

`ios/ExportOptions.plist`（已创建）：`teamID = 4JXH4CSXJ2`、`method = app-store`、`signingStyle = automatic`。

### 3.4 构建命令

```bash
flutter build ipa --export-options-plist=ios/ExportOptions.plist
# 输出：build/ios/ipa/中导物联.ipa（名称取自 CFBundleDisplayName）
```

> `flutter build ios` 走 Apple 自动化签名，需本机 Xcode 已登录对应开发者账号；
> JPush iOS 端需要把该 Bundle ID 的 APNs 推送证书上传到极光控制台（生产环境）。

## 4. 与推送的耦合（重要）

- **包名即推送身份**：包名已由 `uni.app.UNI662B0B4` 统一改为 `com.zdiot.app`，
  极光 AppKey `0ee065e1a4024ce1801fa6d3`（Android / iOS 共用）已绑定到该包名。
  今后若再换包名，必须先在极光控制台登记新包名，取得新 AppKey 后回填
  `lib/services/push/push_config.dart`（iOS + Dart）与
  `android/app/build.gradle.kts` 的 `manifestPlaceholders["JPUSH_APPKEY"]`（Android），
  否则两端收不到推送；同时 iOS 需按新 Bundle ID 重新制作生产 APNs 证书并上传极光控制台。
- **渠道号**：`JPUSH_CHANNEL` 仅为初始值，Android 运行时会被 Dart 的
  `PushConfig.channel` 覆盖（插件 `setup()` 中调用 `setChannel`）；改渠道号只需改
  `push_config.dart` 一处。
- **iOS APNs 环境**：`lib/services/push/push_config.dart` 的 `iosProduction = true`，
  对应生产环境；打包时 `Runner.entitlements` 的 `aps-environment = production`。
- 详见 `docs/jpush-integration.md`。
