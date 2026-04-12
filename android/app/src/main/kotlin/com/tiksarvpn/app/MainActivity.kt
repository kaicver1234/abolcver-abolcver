package com.tiksarvpn.app

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
     * Check if VPN is currently active by checking system network capabilities
     * This is the most reliable way to detect VPN state
     */
    private fun isVpnActive(): Boolean {
        return try {
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNetwork: Network? = connectivityManager.activeNetwork
                if (activeNetwork != null) {
                    val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
                    // Check if the active network has VPN transport
                    networkCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                } else {
                    false
                }
            } else {
                // For older Android versions, check all networks
                @Suppress("DEPRECATION")
                val allNetworks = connectivityManager.allNetworks
                allNetworks.any { network ->
                    val networkCapabilities = connectivityManager.getNetworkCapabilities(network)
                    networkCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error checking VPN state: ${e.message}")
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
