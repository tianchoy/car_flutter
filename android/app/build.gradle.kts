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
