# App 版本更新功能 · 实现计划

## 1. 背景与目标

车联网 App「中导物联」目前没有版本更新能力：用户无法获知新版本，也无法自助升级。

**目标**：App 检测到服务端有新版本时，弹出提示框；用户点击「更新」后自动完成升级。

**验收标准**：
- 启动后（或进入关键页面后）能检测到新版本并弹框
- 弹框展示新版本号、更新说明，区分「强制更新 / 可选更新」
- Android：点击更新 → 应用内下载 APK（含进度）→ 调起系统安装
- iOS：点击更新 → 跳转 App Store（iOS 无法应用内安装）
- 不重复打扰：用户选择「稍后再说」后，本次会话不再弹出

---

## 2. 现状梳理

| 能力 | 状态 | 说明 |
|------|------|------|
| 版本号读取 | ✅ 已有 | `package_info_plus`，`AppConfig.appVersion` / `appBuildNumber`，启动时 `initAppInfo()` 读取 |
| 网络层 | ✅ 已有 | `ApiService`（Dio）+ Repository 模式，`HttpService` 统一注入 token / clientId |
| 弹框 | ✅ 已有 | `showAppConfirmDialog` / `showAppActionSheet` / `app_bottom_sheet.dart`，Cupertino 风格 |
| 外部跳转 | ✅ 已有 | `url_launcher`（可用于跳 App Store / 兜底网页） |
| 本地存储 | ✅ 已有 | `shared_preferences`（记录「忽略该版本」） |
| 文件下载 | ✅ 已有（Dio） | `dio.download()` 支持流式下载 + 进度回调，**无需新增下载库** |
| 下载目录 | ⚠️ 缺显式依赖 | 需新增 `path_provider` |
| 打开 APK 安装 | ⚠️ 缺失 | 需新增 `open_filex`（调起系统安装器）或等价方案 |
| Android 安装权限/FileProvider | ⚠️ 缺失 | 需改 `AndroidManifest.xml` + 新增 `file_paths.xml` |
| **版本检查接口** | ❌ 后端缺失 | **首要前置依赖，需后端配合**（见 §4） |

---

## 3. 整体方案（分平台策略）

```
                    ┌─────────────────────────┐
                    │  请求「检查更新」接口      │
                    │  GET /app/version/check  │
                    └───────────┬─────────────┘
                                │ 返回最新版本号 / 下载地址 / 是否强制 / 更新说明
                                ▼
                   ┌──── 比较 buildNumber ────┐
                   │  latest > 当前 ?          │
                   └─────┬─────────┬─────────┘
                        否        是
                        │         ▼
                    不处理    弹出更新提示框
                        │         │
                  ┌─────┴────┐    └────────┬────────────┐
                  │  稍后再说  │       强  制       非强制
                  └───────────┘         │              │
                                       ┌▼──────────────▼┐
                                       │  立即更新        │
                                       └──┬───────────┬──┘
                                    Android        iOS
                                    ┌▼──────────┐  ┌▼─────────────┐
                                    │ 下载 APK   │  │ 跳转 App Store│
                                    │ 调系统安装  │  └──────────────┘
                                    └───────────┘
```

- **Android**：应用内下载 APK → 调起系统安装器（「点击更新自动更新」的核心）。
- **iOS**：受平台限制无法应用内安装普通发布包，统一跳转 App Store。
- **强制更新**：弹框不可关闭（iOS 无法真正强制，只能强提示 + 跳商店）。

---

## 4. 后端接口契约（需后端确认，阻塞项）

建议新增接口（沿用现有路由风格、匿名或登录态均可）：

```
GET /app/version/check
```

响应沿用项目现有 `ApiResponse` 统一包体（`code / msg / data`），`data` 建议字段：

```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "latestVersion": "1.2.0",
    "latestBuildNumber": 120,
    "forceUpdate": false,
    "updateNote": "1. 修复地图聚合点不散开的问题\n2. 优化围栏弹框",
    "downloadUrl": "https://cdn.zdiot.cn/app/android/app-release.apk",
    "appStoreUrl": "https://apps.apple.com/cn/app/idxxxxx"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| latestVersion | string | 展示用版本号 |
| latestBuildNumber | int | 用于比较（**以 buildNumber 比较最可靠**，`version` 兜底） |
| forceUpdate | bool | 是否强制更新 |
| updateNote | string | 更新说明，弹框内展示 |
| downloadUrl | string | Android APK 下载地址 |
| appStoreUrl | string | iOS App Store 链接（可空，为空则跳官方商店搜索页兜底） |

> 待确认：后端是否已有类似接口 / 字段命名 / 是否区分渠道（iOS、Android、测试包）。

---

## 5. 实现步骤

### 5.1 新增依赖（`pubspec.yaml`）

```yaml
dependencies:
  path_provider: ^2.1.5   # 获取下载目录
  open_filex: ^4.5.0      # 打开已下载 APK 调起安装器
```

> `dio`（下载）、`package_info_plus`（版本）、`url_launcher`（跳商店）、`shared_preferences`（忽略记录）均已具备。

### 5.2 后端接口接入

1. `lib/services/url.dart`：`ApiEndpoints` 新增 `appVersionCheck = '/app/version/check'`。
2. `lib/services/api_service.dart`：新增
   `Future<Response<dynamic>> checkAppVersion()`。

### 5.3 数据模型（新增）

`lib/models/app/app_update_model.dart`：

```dart
class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final bool forceUpdate;
  final String updateNote;
  final String downloadUrl;   // Android
  final String appStoreUrl;   // iOS
  // fromJson(...)
}
```

### 5.4 更新检查服务（新增）

`lib/services/app_update_service.dart`（Repository 角色）：

- `Future<AppUpdateInfo?> checkForUpdate()`
  - 请求接口，解析 `data`
  - 比较 `latestBuildNumber` 与本地 `int.parse(AppConfig.appBuildNumber)`
  - 有新版 → 返回 `AppUpdateInfo`，否则返回 `null`
- `bool shouldSkip(AppUpdateInfo)` / `markSkip(String version)`
  - 用 `shared_preferences` 记录「忽略的版本号」，非强制更新时本次会话内不再弹

### 5.5 下载与安装服务（新增，Android）

`lib/services/app_updater_installer.dart`：

- `Future<String> downloadApk(String url, {ProgressCallback? onProgress})`
  - 用 `dio.download()` 流式写盘到 `getApplicationDocumentsDirectory()`（或临时目录）
  - 回调进度（0~1）供 UI 展示
- `Future<void> installApk(String path)`
  - 调 `OpenFilex.open(path)` 触发系统安装器
- Android 8+ 未知来源权限处理：
  - `OpenFilex.open` 前检测/引导用户开启「允许安装未知来源应用」，必要时跳系统设置页

### 5.6 Android 原生配置

1. `android/app/src/main/AndroidManifest.xml` 新增：
   - `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />`
   - `<provider>` 声明 FileProvider（`androidx.core.content.FileProvider`），`authorities="${applicationId}.fileprovider"`
2. 新增 `android/app/src/main/res/xml/file_paths.xml`：配置 `external-files-path` 等共享路径。

> iOS 无需原生改动（仅跳 App Store）。

### 5.7 更新弹框 UI（新增）

`lib/widgets/app_update_dialog.dart`（Cupertino 风格，复用现有配色/`showCupertinoDialog`）：

- 展示：标题「发现新版本」、`latestVersion`、`updateNote`
- 按钮：
  - 非强制：`稍后再说`（返回并记录忽略）+ `立即更新`
  - 强制：仅 `立即更新`，拦截关闭
- 点击 `立即更新` 后：
  - iOS → `url_launcher` 打开 `appStoreUrl`
  - Android → 弹框切换为下载进度态（进度条 + 百分比），完成后调起安装

### 5.8 触发时机（挂载点）

1. **冷启动静默检查**：`App` 首页加载后（`home_view` / `home_controller` 的 `onReady`）延迟 1~2 秒调用 `checkForUpdate()`，有更新则弹框。
2. **手动检查入口**（可选，建议加）：个人中心 `profile_view` 的版本号行 `AppConfig.appVersionLabel` 增加「检查更新」点击。

---

## 6. 关键交互流程

**Android 更新全流程**：
1. 检测到新版本 → 弹框
2. 用户点「立即更新」
3. 弹框转为下载进度（progress 0% → 100%）
4. `dio.download` 写入本地 `app-release.apk`
5. `OpenFilex.open(apkPath)` → 系统弹出安装确认
6. 首次安装需用户开启「未知来源」权限（系统引导）
7. 用户确认 → 安装完成

**失败/边界处理**：
- 下载失败 → 提示「下载失败，请重试」，可重试
- 接口超时/无网 → 静默忽略，不打扰用户
- 强制更新场景下载失败 → 保留弹框，提示重试

---

## 7. 风险与注意点

| 风险 | 说明 | 应对 |
|------|------|------|
| 后端接口缺失 | 目前无版本检查接口 | **先行与后端对齐 §4 契约**，再开发客户端 |
| Android 未知来源权限 | Android 8+ 需用户授权 | 首次安装时引导开启，做好文案 |
| 大 APK 下载内存 | 78MB 量级 | 必须用 `dio.download` 流式落盘，禁止读入内存 |
| iOS 无法应用内安装 | 平台限制 | 仅跳 App Store，文档中向用户说明 |
| 强制更新 iOS 不可真正强制 | 系统弹框可被规避 | 采用强提示 + 每次启动重复弹的策略 |
| 版本比较精度 | 版本号字符串易错 | 以 `buildNumber`（int）比较为主 |
| 下载目录被清理 | 临时目录可能被系统回收 | 使用 Documents/外部缓存目录，安装前校验文件存在 |

---

## 8. 待确认事项（需用户/后端答复）

1. **后端是否有/能否新增版本检查接口**？字段是否按 §4 约定？（最关键）
2. Android APK 分发地址（`downloadUrl`）由谁提供？（自建 CDN / 蒲公英 / 其他）
3. iOS 是否已上架 App Store、App Store 链接是多少？
4. 是否需要「强制更新」机制？
5. 更新检测触发时机：仅冷启动，还是也要「个人中心手动检查」？
6. Android 安装方案确认：应用内下载安装（本计划主方案）vs 仅跳转应用市场/网页？

---

## 9. 任务清单（实现阶段待办）

- [ ] 与后端对齐版本检查接口契约（§4）
- [ ] 新增依赖 `path_provider`、`open_filex`
- [ ] `ApiEndpoints` + `ApiService.checkAppVersion()`
- [ ] 新增 `AppUpdateInfo` 模型
- [ ] 新增 `app_update_service.dart`（检查 + 忽略记录）
- [ ] 新增 `app_updater_installer.dart`（下载 + 安装）
- [ ] Android 原生配置（Manifest + file_paths.xml）
- [ ] 新增 `app_update_dialog.dart`（弹框 + 下载进度）
- [ ] 挂载冷启动检测 + 个人中心手动入口
- [ ] 真机验证（Android 需测试包 + 可下载 APK 地址）
