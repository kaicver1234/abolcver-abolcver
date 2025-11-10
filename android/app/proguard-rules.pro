# Tiksar VPN ProGuard Rules - Optimized for Size

# ===== Flutter Core (Only Essential) =====
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class io.flutter.embedding.engine.loader.FlutterLoader { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-dontwarn io.flutter.**

# ===== V2Ray Core & Native (Critical Only) =====
-keep class libv2ray.** { *; }
-keep class go.** { *; }
-dontwarn libv2ray.**
-dontwarn go.**

# ===== Native Methods =====
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# ===== Remove Kotlin Reflection (Save Space!) =====
-dontwarn kotlin.**
-dontwarn kotlinx.**
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    public static void check*(...); 
    public static void throw*(...); 
}

# ===== Networking (Minimal) =====
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# ===== Firebase (Minimal) =====
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ===== Remove Logging (Save Space!) =====
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# ===== Services & Receivers =====
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Activity

# ===== Essential Attributes =====
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# ===== Parcelable =====
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
