####################################################################################################
# Flutter & Dart
####################################################################################################
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter embedding
-keepclassmembers class * {
    @io.flutter.embedding.engine.dart.DartEntrypoint *;
}

# Dart FFI
-keep class dart.** { *; }
-keep class ** extends dart.jni.JniObject { *; }

####################################################################################################
# V2Ray & Go Native
####################################################################################################
-keep class com.v2ray.** { *; }
-keep class go.** { *; }
-keep class libv2ray.** { *; }
-keep class tun2socks.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# V2Ray interfaces
-keep interface com.v2ray.** { *; }
-keep interface libv2ray.** { *; }

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
-keep class com.tiksarvpn.** { *; }
-keep class com.tiksarvpn.app.** { *; }

# Keep method channel classes
-keep class com.tiksarvpn.app.*MethodChannel { *; }
-keep class com.tiksarvpn.app.*MethodChannel$* { *; }

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
# Don't optimize away classes that may be used reflectively
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
