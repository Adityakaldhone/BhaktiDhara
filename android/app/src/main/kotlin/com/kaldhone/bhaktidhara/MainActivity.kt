package com.kaldhone.bhaktidhara

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 9109
    }

    private var pendingLocationPermissionResult: MethodChannel.Result? = null
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bhaktidhara/location_permission")
            .setMethodCallHandler { call, result ->
                if (call.method != "requestLocationPermission") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val fineGranted = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
                val coarseGranted = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
                if (fineGranted || coarseGranted || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    result.success("whileInUse")
                    return@setMethodCallHandler
                }
                // Clear any stale callback before issuing a new request so a
                // MethodChannel.Result can never receive two replies.
                pendingLocationPermissionResult?.success("denied")
                pendingLocationPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                    ),
                    LOCATION_PERMISSION_REQUEST_CODE,
                )
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            val pending = pendingLocationPermissionResult
            pendingLocationPermissionResult = null
            if (pending == null) return

            if (grantResults.isEmpty()) {
                pending.success("denied")
                return
            }
            val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
            if (granted) {
                pending.success("whileInUse")
                return
            }
            val canShowRationale =
                ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                ) || ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                )
            pending.success(if (canShowRationale) "denied" else "deniedForever")
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        pendingLocationPermissionResult = null
        super.onDestroy()
    }
}
