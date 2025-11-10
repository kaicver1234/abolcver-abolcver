# Tiksar VPN ProGuard Rules - Tested & Error-Free
# Simple and safe configuration for VPN apps

# ===== Flutter =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ===== V2Ray Core & Native Libraries =====
-keep class libv2ray.** { *; }
-keep class com.v2ray.** { *; }
-keep class go.** { *; }
-dontwarn libv2ray.**
-dontwarn go.**

# ===== Native Methods =====
-keepclasseswithmembernames class * {
    native <methods>;
}

# ===== Kotlin =====
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# ===== Networking =====
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ===== Firebase & Google Services =====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ===== Gson =====
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# ===== AndroidX =====
-keep class androidx.** { *; }
-dontwarn androidx.**

# ===== App Package =====
-keep class com.tiksarvpn.app.** { *; }

# ===== Keep Services & Receivers =====
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver

# ===== Crash Reports =====
-keepattributes SourceFile,LineNumberTable

# ===== Parcelable =====
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ===== Serializable =====
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
}

# ===== Enum =====
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
