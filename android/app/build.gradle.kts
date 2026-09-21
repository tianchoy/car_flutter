import java.util.Properties

plugins {
    id("com.android.application")
    // 删除 id("kotlin-android")，AGP 9.0 内置 Kotlin 支持
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 发布签名配置：android/key.properties（已被 android/.gitignore 忽略）。
// 缺省时回退到 debug 签名，保证没有证书的环境也能编译。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "com.zdiot.app"
    // permission_handler_android 要求 compileSdk >= 37；AGP 9.0 会给出推荐值 36 的
    // 警告，但 37 可正常编译，因此保持在 37。
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeType = (keystoreProperties["storeType"] as String?) ?: "PKCS12"
            }
        }
    }

    defaultConfig {
        // 统一包名 com.zdiot.app：
        // - 极光推送 AppKey 与包名一一对应，改包名必须同步在极光控制台登记；
        // - 换包名后无法覆盖安装旧包（旧包 uni.app.UNI662B0B4 需单独卸载）。
        val appId = "com.zdiot.app"
        applicationId = appId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // 版本号统一由 pubspec.yaml 的 version（如 1.0.5+105）驱动。
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["JPUSH_PKGNAME"] = appId
        // AppKey 需与 lib/services/push/push_config.dart 的 appKey 保持一致（两端共用）。
        manifestPlaceholders["JPUSH_APPKEY"] = "0ee065e1a4024ce1801fa6d3"
        manifestPlaceholders["JPUSH_CHANNEL"] = "developer-default"

        // ===== 极光厂商通道（华为 / 荣耀 / 小米 / OPPO）=====
        // 这些值会注入到各厂商 SDK AAR 及本工程 AndroidManifest 的对应 meta-data。
        // 华为：AppID 与 android/app/agconnect-services.json 的 app_id 一致（另需 AGC 插件）。
        manifestPlaceholders["HUAWEI_APPID"] = "119069041"
        // 荣耀：仅 AppID，无前缀。
        manifestPlaceholders["HONOR_APPID"] = "104591945"
        // 小米：v5.5.3 起无需 "MI-" 前缀。
        manifestPlaceholders["XIAOMI_APPID"] = "2882303761520585420"
        manifestPlaceholders["XIAOMI_APPKEY"] = "5172058551420"
        // OPPO：AppID / AppKey / AppSecret 三个值都必须带 "OP-" 前缀。
        manifestPlaceholders["OPPO_APPID"] = "OP-37752444"
        manifestPlaceholders["OPPO_APPKEY"] = "OP-be93df7882354270988303db2a9a57f6"
        manifestPlaceholders["OPPO_APPSECRET"] = "OP-ec666304e321424f976f7fb1ec5bb2eb"
    }

    buildTypes {
        debug {
            // 与线上包使用同一本证书：避免 debug / release 互相覆盖安装失败，
            // 也便于需要校验 APK 签名的第三方 SDK 调试。
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // release 会执行 R8，必须保留极光与华为/荣耀/小米/OPPO 厂商 SDK 的类，
            // 否则厂商通道会静默注册失败（离线收不到推送）。
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// 新增：Kotlin 编译器配置（替代已废弃的 android.kotlinOptions）
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// ================= 极光厂商通道 SDK =================
// 版本必须与 jpush_flutter 内置的 cn.jiguang.sdk:jpush:6.2.1 完全一致，
// 否则厂商通道注册会失败。华为/荣耀/OPPO 的厂商 SDK 由极光插件自动拉取。
dependencies {
    implementation("cn.jiguang.sdk.plugin:huawei:6.2.1")
    implementation("cn.jiguang.sdk.plugin:honor:6.2.1")
    implementation("cn.jiguang.sdk.plugin:xiaomi:6.2.1")
    implementation("cn.jiguang.sdk.plugin:oppo:6.2.1")
    // OPPO 3.1.0 及以上 aar 依赖；缺失时 OPPO 通道运行时可能 ClassNotFoundException。
    implementation("com.google.code.gson:gson:2.6.2")
    implementation("androidx.annotation:annotation:1.1.0")
}

// 华为 AGC 插件：解析 android/app/agconnect-services.json（华为厂商通道必需）。
// 华为未发布 Gradle plugin marker，故用 apply 方式而非 plugins {} DSL。
apply(plugin = "com.huawei.agconnect")
