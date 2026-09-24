# 项目长期记忆 — car_flutter

## 项目标识
- Flutter 工程名 `car`，应用显示名 **中导物联**，包名/namespace `com.zdiot.app`。
- 版本号由 `pubspec.yaml` 的 `version`（形如 `1.1.0+110`）统一驱动，Android 端 `versionCode`/`versionName` 均从 `flutter.versionCode` / `flutter.versionName` 取值，**不要**在 `build.gradle.kts` 里硬编码。
- Flutter SDK: `/Users/xyhc/Documents/flutter`（3.47.3 stable）｜JDK 17｜Gradle 9.1.0｜compileSdk 37、targetSdk 36。

## Android 发布签名
- 配置文件 `android/key.properties`（被 `android/.gitignore` 忽略），含 `storeFile`/`storePassword`/`keyAlias`/`keyPassword`/`storeType`。
- 证书文件：`/Users/xyhc/Documents/app-signing/zdiot.p12`，storeType **PKCS12**。
- 证书 DN：`CN=Liu, OU=zdiot, O=zdiot_car, L=hz, ST=sd, C=cn`，SHA-256 `2cd942ac…70f8e`。
- **debug 与 release 共用同一本证书**（避免互相覆盖安装失败）。
- `build.gradle.kts` 中 `key.properties` 缺失时会回退 debug 签名，因此出包后**务必校验签名**。

## 打包命令
```bash
cd /Users/xyhc/Documents/car_flutter
flutter build apk --release          # 通用包（fat APK）
# 产物：build/app/outputs/flutter-apk/app-release.apk
```
- 通用包 ABI：`arm64-v8a` / `armeabi-v7a` / `x86_64`（不含 x86）。
- release 启用 R8，`proguard-rules.pro` 必须保留极光 + 华为/荣耀/小米/OPPO 厂商 SDK 的类，否则厂商通道静默注册失败（离线收不到推送）。
- 想减小体积可用 `--split-per-abi`（产物变成多个 `app-<abi>-release.apk`）。

## 推送（极光 JPush）
- AppKey `0ee065e1a4024ce1801fa6d3`，需与 `lib/services/push/push_config.dart` 保持一致。
- AppKey 与包名一一对应，**改包名必须在极光控制台同步登记**。
- 版本号需与插件内置 `cn.jiguang.sdk:jpush:6.2.1` 严格一致，厂商 SDK 依赖见 `android/app/build.gradle.kts`。
- 旧包 `uni.app.UNI662B0B4` 无法被覆盖安装，需单独卸载。

## 环境注意事项
- 项目根 `.env`（32 字节）为源文件，`build/unit_test_assets/.env` 只是拷贝；执行 `flutter clean` 不会影响源文件。
- `flutter clean` 会同时删除 `.dart_tool/`，之后必须 `flutter pub get`。

## URL 配置
- 业务 API：`https://gpsapp.zdiot.cn`。
- 地图瓦片：高德 `https://wprd0{s}.is.autonavi.com/appmaptile?...`（`lib/services/url.dart` 的 `amapTileUrl`）。
- **该域名是纯 API 后端，未部署静态页面**。`/privacy-policy`、`/user-agreement` 返回 HTTP 200 但 body 是 `{"code":404,...}`。排查该域名下的资源时**必须看响应体，不能只看 HTTP 状态码**。

## 协议页与隐私合规（2026-09-24 已整改）
- 用户协议 / 隐私政策**内置为本地 HTML**：`assets/legal/privacy_policy.html`、`assets/legal/user_agreement.html`（已在 `pubspec.yaml` 注册 `assets/legal/`）。**不要再改回跳服务端 URL**。
- 入口统一走 `LegalLinks.openAgreement()` / `openPrivacyPolicy()` → `Routes.webContent` + `WebContentRouteArgs.assetPath` → `loadFlutterAsset()`。
- 首次启动隐私同意门：`PrivacyConsentService`（key `legal.privacy_policy_agreed.v1`）+ `Routes.privacyConsent` + `PostConsentBootstrap`。
- **约定：任何会初始化采集类 SDK 的调用（含 `clearBadge()`、前后台监听注册）都必须放在 `PostConsentBootstrap` 内**，不得回到 `main.dart` 直接调用。新增此类初始化请追加到该文件。
- Android 安全配置：`android:allowBackup="false"`、`usesCleartextTraffic="false"`、`@xml/network_security_config`（默认禁止明文）。业务与地图均为 HTTPS，dex 扫描确认无明文端点。
- `ACCESS_BACKGROUND_LOCATION` 为**功能必需**（围栏进出提醒），不要移除。

## 待办（阻塞上架）
- 协议 HTML 中的 `【待填写：...】` 占位符（公司全称、地址、邮箱、电话、管辖法院）必须替换为真实信息。
- 隐私政策文案需法务复核。
- `flutter test` 在本机环境无法运行（`flutter_tester` WebSocket 报错，所有测试文件均如此）；验证改动请用逐条断言核对 + `flutter analyze`。
