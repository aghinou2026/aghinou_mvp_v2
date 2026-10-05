package com.aghinou.app

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.aghinou.app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playMessageSound" -> {
                        try {
                            val tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
                            tone.startTone(ToneGenerator.TONE_PROP_ACK, 280)
                            android.os.Handler(mainLooper).postDelayed({ tone.release() }, 250)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SOUND_ERROR", "پخش صدای اعلان انجام نشد", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
