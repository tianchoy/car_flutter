// 厂商通道（华为 / 荣耀）所需的 Maven 仓库与华为 AGC Gradle 插件。
// 华为 AGC 没有发布 Gradle plugin marker，只能通过 buildscript classpath 引入，
// 再由 app 模块 apply(plugin = "com.huawei.agconnect")。
buildscript {
    repositories {
        google()
        mavenCentral()
        // 华为 AGC / HMS Push 插件仓库
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
    dependencies {
        // 华为 AGC（Push Kit）插件：编译期解析 android/app/agconnect-services.json
        classpath("com.huawei.agconnect:agcp:1.9.6.300")
        // 两个作用：
        // 1) agcp 的 GradleVersionTool 需要从 buildscript classpath 探测 AGP 版本，缺失会抛 "No value present"；
        // 2) 用 9.0.1 压过 agcp 传递依赖的旧版 AGP（早于 7.3），否则 android{} 会解析到没有
        //    namespace/compileSdk 的旧 BaseAppModuleExtension，导致脚本编译失败。
        classpath("com.android.tools.build:gradle:9.0.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // 华为 HMS Push / AGC 依赖仓库
        maven { url = uri("https://developer.huawei.com/repo/") }
        // 荣耀推送依赖仓库（极光荣耀通道 v5.9.0 起需要）
        maven { url = uri("https://developer.hihonor.com/repo") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
