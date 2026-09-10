package id.akademihub.akademihub_mob

import android.app.ActivityManager
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val KIOSK_CHANNEL = "com.akademihub.app/kiosk"
    private val DEVICE_CHANNEL = "id.akademihub/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (getSystemService(UiModeManager::class.java)?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTelevision" -> {
                    val uiModeManager = getSystemService(UiModeManager::class.java)
                    val isTv = uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
                    result.success(isTv)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            startLockTask()
                            
                            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val isPinned = am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                            result.success(isPinned)
                        } else {
                            result.error("UNSUPPORTED", "SDK version not supported", null)
                        }
                    } catch (e: Exception) {
                        result.error("FAILED", e.message, null)
                    }
                }
                "stopKioskMode" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            if (am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE) {
                                stopLockTask()
                            }
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(true)
                        } else {
                            result.error("UNSUPPORTED", "SDK version not supported", null)
                        }
                    } catch (e: Exception) {
                        result.error("FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}


