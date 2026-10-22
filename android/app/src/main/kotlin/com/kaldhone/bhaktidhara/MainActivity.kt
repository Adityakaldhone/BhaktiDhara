package com.kaldhone.bhaktidhara

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                ?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    // Untagged short vibrations are reclassified by Android as USAGE_TOUCH and
    // dropped when touch haptics are off (the default on vivo and others).
    // Tagging them as media keeps them under the media vibration setting.
    private fun play(v: Vibrator, effect: VibrationEffect) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            @Suppress("DEPRECATION")
            v.vibrate(effect, attrs)
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bhaktidhara/vibration")
            .setMethodCallHandler { call, result ->
                val v = vibrator
                if (v == null || !v.hasVibrator()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "vibrate" -> {
                        val ms = (call.argument<Int>("duration") ?: 30).toLong()
                        val amplitude = call.argument<Int>("amplitude") ?: -1
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val amp = if (amplitude in 1..255 && v.hasAmplitudeControl()) {
                                amplitude
                            } else {
                                VibrationEffect.DEFAULT_AMPLITUDE
                            }
                            play(v, VibrationEffect.createOneShot(ms, amp))
                        } else {
                            @Suppress("DEPRECATION")
                            v.vibrate(ms)
                        }
                        result.success(true)
                    }
                    "pattern" -> {
                        val timings = call.argument<List<Int>>("pattern")
                            ?.map { it.toLong() }?.toLongArray()
                        if (timings == null || timings.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            play(v, VibrationEffect.createWaveform(timings, -1))
                        } else {
                            @Suppress("DEPRECATION")
                            v.vibrate(timings, -1)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
