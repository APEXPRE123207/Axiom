package com.axiom.axiom_tablet

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "axiom/haptics"
    private val TAG = "AxiomHaptics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "vibrate" -> {
                    val duration = call.argument<Int>("duration")?.toLong() ?: 50L
                    val amplitude = call.argument<Int>("amplitude") ?: 255
                    val didVibrate = performVibrate(duration, amplitude)
                    result.success(didVibrate)
                }
                "hasVibrator" -> {
                    result.success(getVibrator()?.hasVibrator() == true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getVibrator(): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error obtaining vibrator service: ${e.message}")
            null
        }
    }

    private fun performVibrate(durationMs: Long, amplitude: Int): Boolean {
        var success = false

        // 1. Force View Haptic Feedback (System level)
        try {
            val flags = HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING or HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING
            window?.decorView?.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY, flags)
            window?.decorView?.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP, flags)
        } catch (e: Exception) {
            Log.w(TAG, "View haptics error: ${e.message}")
        }

        // 2. Direct Hardware Vibrator motor access with minimum 50ms pulse for ERM motors
        try {
            val vibrator = getVibrator()
            if (vibrator != null && vibrator.hasVibrator()) {
                val effectiveDuration = if (durationMs < 45L) 50L else durationMs

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val hasAmpControl = vibrator.hasAmplitudeControl()
                    val effect = if (hasAmpControl) {
                        VibrationEffect.createOneShot(effectiveDuration, amplitude.coerceIn(1, 255))
                    } else {
                        // Samsung tablets without amplitude control require DEFAULT_AMPLITUDE (-1)
                        VibrationEffect.createOneShot(effectiveDuration, VibrationEffect.DEFAULT_AMPLITUDE)
                    }
                    vibrator.vibrate(effect)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(effectiveDuration)
                }
                success = true
                Log.d(TAG, "Vibrated successfully for ${effectiveDuration}ms")
            } else {
                Log.d(TAG, "Tablet does not have a physical vibration motor")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Hardware vibration failed: ${e.message}")
        }

        return success
    }
}
