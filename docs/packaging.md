# 打包配置说明（Android / iOS）

本说明对应 `car_flutter` 工程的发布打包配置，数值取自 uni-app X 源工程的离线打包项目
（`car` 安卓端、`car-ios` iOS 端），保证与线上包一致、可覆盖安装。

## 1. 基础信息（两端统一）

| 项 | 值 |
| --- | --- |
| 应用名称 | 中导物联 |
| Android 包名 / iOS Bundle ID | `uni.app.UNI662B0B4` |
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
| `namespace` / `applicationId` | `uni.app.UNI662B0B4` | 与极光推送 AppKey 绑定 |
| `minSdk` | `24` | 与源工程一致 |
| `targetSdk` | `36` | 与源工程一致 |
| `compileSdk` | `37` | `permission_handler` 要求 ≥37（AGP 9.0 会提示推荐 36，但可正常编译） |

### 2.4 极光推送占位符

`manifestPlaceholders`：`JPUSH_PKGNAME` = applicationId、`JPUSH_APPKEY` = `a53c28d734057573f67e16f7`、`JPUSH_CHANNEL` = `developer-default`，
并在 `AndroidManifest.xml` 注入 `JPUSH_APPKEY` / `JPUSH_CHANNEL` 的 meta-data。

## 3. iOS

### 3.1 签名

| 项 | 值 |
| --- | --- |
| Bundle ID | `uni.app.UNI662B0B4` |
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

- **包名即推送身份**：`uni.app.UNI662B0B4` 与极光 AppKey `a53c28d734057573f67e16f7`
  在极光控制台一一绑定。若要换包名，必须先在极光控制台登记新包名，否则两端收不到推送。
- **iOS APNs 环境**：`lib/services/push/push_config.dart` 的 `iosProduction = true`，
  对应生产环境；打包时 `Runner.entitlements` 的 `aps-environment = production`。
- 详见 `docs/jpush-integration.md`。
