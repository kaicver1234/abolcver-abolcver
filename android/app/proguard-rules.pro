####################################################################################################
# Flutter & Dart
####################################################################################################
-keep,allowshrinking,allowoptimization class io.flutter.app.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.plugin.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.util.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.view.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.plugins.** { *; }
-keep,allowshrinking,allowoptimization class io.flutter.embedding.** { *; }

# Flutter embedding - NO optimization for annotations
-keepclassmembers class * {
    @io.flutter.embedding.engine.dart.DartEntrypoint *;
}

# Dart FFI - NO optimization
-keep class dart.** { *; }
-keep class ** extends dart.jni.JniObject { *; }

####################################################################################################
# V2Ray & Go Native
####################################################################################################
-keep,allowshrinking,allowoptimization class com.v2ray.** { *; }
-keep,allowshrinking,allowoptimization class go.** { *; }
-keep,allowshrinking,allowoptimization class libv2ray.** { *; }
-keep,allowshrinking,allowoptimization class tun2socks.** { *; }

# Keep all native methods - NO optimization
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep native method names
-keepclassmembernames class * {
    native <methods>;
}

# V2Ray interfaces
-keep,allowshrinking,allowoptimization interface com.v2ray.** { *; }
-keep,allowshrinking,allowoptimization interface libv2ray.** { *; }

####################################################################################################
# Kotlin & Coroutines
####################################################################################################
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.** { *; }
-keep class kotlinx.coroutines.** { *; }

-dontwarn kotlin.**
-dontwarn kotlinx.**

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

####################################################################################################
# Gson & JSON
####################################################################################################
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.**

# Gson uses generic type information stored in a class file when working with fields
-keepattributes Signature

# Gson specific classes
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Application classes that will be serialized/deserialized over Gson
-keep class com.tiksarvpn.app.models.** { *; }

####################################################################################################
# Firebase
####################################################################################################
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

####################################################################################################
# Networking (OkHttp, Retrofit, etc.)
####################################################################################################
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep interface okhttp3.** { *; }
-keep interface okio.** { *; }

# OkHttp platform used only on JVM and when Conscrypt dependency is available
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

####################################################################################################
# Your App Classes
####################################################################################################
-keep,allowshrinking,allowoptimization class com.tiksarvpn.** { *; }
-keep,allowshrinking,allowoptimization class com.tiksarvpn.app.** { *; }

# Keep method channel classes - NO optimization
-keep class com.tiksarvpn.app.*MethodChannel { *; }
-keep class com.tiksarvpn.app.*MethodChannel$* { *; }
-keepclassmembers class com.tiksarvpn.app.*MethodChannel {
    public <methods>;
    public <fields>;
}

# Keep MainActivity - NO optimization
-keep class com.tiksarvpn.app.MainActivity { *; }

####################################################################################################
# Android Components
####################################################################################################
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View

# Keep all View constructors
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep setters in Views
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

####################################################################################################
# Enums
####################################################################################################
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

####################################################################################################
# Parcelable
####################################################################################################
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

####################################################################################################
# Serializable
####################################################################################################
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

####################################################################################################
# Reflection
####################################################################################################
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

####################################################################################################
# WebView
####################################################################################################
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

####################################################################################################
# JavaScript Interface
####################################################################################################
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

####################################################################################################
# Debugging
####################################################################################################
# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Hide original source file name
-renamesourcefileattribute SourceFile

####################################################################################################
# R8 Compatibility
####################################################################################################
-dontwarn java.lang.invoke.StringConcatFactory

####################################################################################################
# Remove Logs in Release
####################################################################################################
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

####################################################################################################
# Optimization
####################################################################################################
# Enable safe optimizations
-dontobfuscate
-dontpreverify

# Conservative optimization - exclude risky optimizations
-optimizations !code/simplification/arithmetic
-optimizations !code/simplification/cast
-optimizations !field/*
-optimizations !class/merging/*
-optimizations !method/removal/parameter
-optimizations !method/propagation/parameter

# Reasonable number of optimization passes
-optimizationpasses 3

# Don't note duplicate definitions
-dontnote **

# Suppress warnings
-dontwarn **
