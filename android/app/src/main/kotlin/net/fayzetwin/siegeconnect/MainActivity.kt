package net.fayzetwin.siegeconnect

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.siegeconnect/vpn_control"
    private val VPN_REQUEST_CODE = 1
    private var pendingConfigPath: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startVpn" -> {
                    val configPath = call.argument<String>("configPath")
                    pendingConfigPath = configPath
                    
                    val vpnIntent = VpnService.prepare(this)
                    if (vpnIntent != null) {
                        startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
                    } else {
                        onActivityResult(VPN_REQUEST_CODE, Activity.RESULT_OK, null)
                    }
                    result.success(null)
                }
                "stopVpn" -> {
                    val intent = Intent(this, SiegeVpnService::class.java).apply {
                        action = SiegeVpnService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "updateAllowedApps" -> {
                    val packages = call.argument<List<String>>("packages")
                    // TODO: Send broadcast or update service
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, SiegeVpnService::class.java).apply {
                action = SiegeVpnService.ACTION_START
                putExtra(SiegeVpnService.EXTRA_CONFIG_PATH, pendingConfigPath)
            }
            startService(intent)
        }
    }
}
