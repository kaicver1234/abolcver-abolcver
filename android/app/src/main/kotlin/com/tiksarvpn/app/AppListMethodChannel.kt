package com.tiksarvpn.app

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

class AppListMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.tiksarvpn.app/app_list"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(AppListMethodChannel(context))
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledApps" -> {
                val includeIcons = (call.argument<Boolean>("withIcons")) ?: false
                // Enumerating apps and rasterizing every launcher icon is heavy
                // work. Doing it on the platform main thread freezes the UI and,
                // with many apps installed, can exhaust the main-thread heap and
                // crash the whole app. Run it on a background thread and post the
                // result back on the main looper (MethodChannel.Result must be
                // replied to on the main thread).
                Thread {
                    try {
                        val apps = loadInstalledApps(includeIcons)
                        mainHandler.post { result.success(apps) }
                    } catch (t: Throwable) {
                        // Catch Throwable, not just Exception, so an
                        // OutOfMemoryError surfaces as a Dart error instead of a
                        // hard native crash.
                        mainHandler.post {
                            result.error("APP_LIST_ERROR", "Failed to get installed apps", t.message)
                        }
                    }
                }.start()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun loadInstalledApps(includeIcons: Boolean): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        val appList = mutableListOf<Map<String, Any>>()

        for (appInfo in installedApps) {
            // Skip system apps that don't have a launcher
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                val launchIntent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                if (launchIntent == null) {
                    continue
                }
            }

            // Skip our own app — it's always allowed implicitly through the VPN
            if (appInfo.packageName == context.packageName) {
                continue
            }

            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val packageName = appInfo.packageName

            val entry = mutableMapOf<String, Any>(
                "name" to appName,
                "packageName" to packageName,
                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
            )

            if (includeIcons) {
                try {
                    val icon = packageManager.getApplicationIcon(appInfo)
                    val bytes = drawableToPngBytes(icon)
                    if (bytes != null) {
                        entry["icon"] = bytes
                    }
                } catch (_: Throwable) {
                    // Skip icon if it cannot be rendered (incl. OOM on a single icon)
                }
            }

            appList.add(entry)
        }

        return appList.sortedBy { (it["name"] as? String)?.lowercase() ?: "" }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray? {
        var bitmap: Bitmap? = null
        // The source bitmap of a BitmapDrawable is shared with the system; never
        // recycle it. Track whether we created a NEW bitmap so we can free it.
        val sharedBitmap = (drawable as? BitmapDrawable)?.bitmap
        return try {
            val size = 64
            bitmap = if (sharedBitmap != null) {
                Bitmap.createScaledBitmap(sharedBitmap, size, size, true)
            } else {
                val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, size, size)
                drawable.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 75, stream)
            stream.toByteArray()
        } catch (_: Throwable) {
            null
        } finally {
            // Recycle only the bitmap we allocated, not the drawable's shared one.
            if (bitmap != null && bitmap != sharedBitmap) {
                bitmap.recycle()
            }
        }
    }
}
