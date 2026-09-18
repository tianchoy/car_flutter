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
    namespace = "uni.app.UNI662B0B4"
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
        // 与 uni-app X 离线工程（car/app/build.gradle）保持一致的包名：
        // - 极光推送 AppKey 与包名一一对应，改包名必须同步在极光控制台登记；
        // - 沿用线上包名，保证覆盖安装与第三方 SDK（厂商推送等）配置一致。
        val appId = "uni.app.UNI662B0B4"
        applicationId = appId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // 版本号统一由 pubspec.yaml 的 version（如 1.0.5+105）驱动。
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["JPUSH_PKGNAME"] = appId
        manifestPlaceholders["JPUSH_APPKEY"] = "a53c28d734057573f67e16f7"
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
