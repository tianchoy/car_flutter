# ============================================================
# 极光推送（JPush）+ 厂商通道 混淆规则
# ------------------------------------------------------------
# release 构建会执行 R8（minifyReleaseWithR8）。厂商 SDK 大量使用
# 反射与 Manifest 中声明的组件（Receiver / Service / Provider），
# 被裁剪或重命名后通道会静默注册失败（表现为离线收不到推送），
# 因此这里按需保留，不做全局 -dontoptimize，避免影响主包优化。
# ============================================================

# ---------- 极光核心（jpush / jcore）----------
-dontwarn cn.jpush.**
-dontwarn cn.jiguang.**
-dontwarn cn.jmessage.**
-keep class cn.jpush.** { *; }
-keep class cn.jiguang.** { *; }
-keep class cn.jmessage.** { *; }
# JPush 自定义 Receiver / Service 通过继承被反射实例化
-keep class * extends cn.jpush.android.service.JPushMessageReceiver { *; }
-keep class * extends cn.jpush.android.service.JPushMessageService { *; }
-keep class * extends cn.jpush.android.service.JCommonService { *; }
# JCore 的 JNI 方法与 aidl
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---------- 华为 HMS Push ----------
-dontwarn com.huawei.**
-keep class com.huawei.hms.** { *; }
-keep class com.huawei.android.hms.** { *; }
-keep class com.huawei.agconnect.** { *; }
-keep interface com.huawei.hms.** { *; }
# HMS 通过 Manifest 声明的组件，需保留类名
-keep public class * extends com.huawei.hms.support.api.push.PushReceiver
-keep public class com.huawei.hms.support.api.push.PushMsgReceiver { *; }
-keep public class com.huawei.hms.support.api.push.service.HmsMsgService { *; }

# ---------- 荣耀 Honor Push ----------
-dontwarn com.hihonor.**
-keep class com.hihonor.** { *; }
-keep interface com.hihonor.** { *; }

# ---------- 小米 Mi Push ----------
-dontwarn com.xiaomi.**
-keep class com.xiaomi.mipush.sdk.** { *; }
-keep class com.xiaomi.push.** { *; }
-keep class com.xiaomi.channel.** { *; }
-keep public class * extends com.xiaomi.mipush.sdk.PushMessageReceiver
# 小米 SDK 通过反射读取枚举与注解
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ---------- OPPO / heytap Push ----------
-dontwarn com.heytap.**
-dontwarn com.coloros.**
-keep class com.heytap.** { *; }
-keep class com.coloros.** { *; }
-keep public class * extends com.heytap.msp.push.service.CompatibleDataMessageCallbackService
-keep public class * extends com.heytap.msp.push.service.DataMessageCallbackService

# ---------- 通用：序列化与回调 ----------
# 推送附加字段（JPush 的 extras）经 JSON 传递，保留 gson 相关
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
