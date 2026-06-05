package com.tiksarvpn.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tiksarvpn.app/vpn_control"
    private val VPN_STATE_CHANNEL = "com.tiksarvpn.app/vpn_state"
    private var vpnControlChannel: MethodChannel? = null
    private var vpnStateChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent in onCreate for fresh app starts
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppListMethodChannel.registerWith(flutterEngine, context)
        PingMethodChannel.registerWith(flutterEngine, context)
        SettingsMethodChannel.registerWith(flutterEngine, context)
        
        // Create VPN control channel for notification disconnect
        vpnControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Create VPN state channel to check system VPN state
        vpnStateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_STATE_CHANNEL)
        vpnStateChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isVpnActive" -> {
                    result.success(isVpnActive())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    /**
     * Check if **OUR** VPN is currently active.
     *
     * The previous implementation checked only `TRANSPORT_VPN`, which is
     * true whenever ANY VPN app on the device has an active tunnel — so if
     * the user paused our app, switched to another VPN, then reopened our
     * app, the UI would falsely show "connected" because the foreign VPN
     * was active.
     *
     * The fix combines two signals:
     *   1. The OS reports a VPN tunnel is up (TRANSPORT_VPN).
     *   2. OUR own V2rayVPNService is currently running in our process.
     * Both must be true for us to claim "connected".
     */
    private fun isVpnActive(): Boolean {
        return try {
            // Signal 1: is there ANY VPN tunnel up on the device?
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val anyVpnUp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNetwork: Network? = connectivityManager.activeNetwork
                activeNetwork != null &&
                    connectivityManager.getNetworkCapabilities(activeNetwork)
                        ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
            } else {
                @Suppress("DEPRECATION")
                connectivityManager.allNetworks.any { network ->
                    connectivityManager.getNetworkCapabilities(network)
                        ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                }
            }

            if (!anyVpnUp) return false

            // Signal 2: is OUR VpnService running? If a foreign VPN is the
            // one holding the tunnel, our service will not be in the list.
            isOurVpnServiceRunning()
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking VPN state: ${e.message}")
            false
        }
    }

    /**
     * Returns true if our V2rayVPNService is currently running in our
     * process. getRunningServices() is deprecated on O+ for inspecting
     * OTHER apps, but it still returns services from the caller's own
     * package, which is exactly what we need.
     */
    @Suppress("DEPRECATION")
    private fun isOurVpnServiceRunning(): Boolean {
        return try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val ourPkg = packageName
            am.getRunningServices(Int.MAX_VALUE).any { svc ->
                svc.service.packageName == ourPkg &&
                    svc.service.className.endsWith("V2rayVPNService")
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking our service: ${e.message}")
            // If we can't tell, be conservative and say no — better to show
            // "disconnected" wrongly than claim a foreign VPN as ours.
            false
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Update the intent and handle it
        setIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        // Handle any pending intents
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "FROM_DISCONNECT_BTN") {
            // Send message to Flutter to disconnect VPN
            vpnControlChannel?.invokeMethod("disconnectFromNotification", null)
            // Clear the intent action to prevent repeated handling
            intent.action = null
        }
    }
}
