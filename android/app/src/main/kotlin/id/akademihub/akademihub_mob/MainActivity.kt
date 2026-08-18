package id.akademihub.akademihub_mob

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.akademihub.app/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            startLockTask()
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            
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
                            stopLockTask()
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

