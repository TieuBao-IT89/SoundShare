package com.example.musicapp

import com.ryanheise.audioservice.AudioServiceActivity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundshare/share")
            .setMethodCallHandler { call, result ->
                val link = call.arguments as? String
                if (call.method != "share" || link == null || link.length > 2048) {
                    result.notImplemented()
                } else {
                    try {
                        startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, link)
                        }, null))
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("SHARE_UNAVAILABLE", "Sharing unavailable", null)
                    }
                }
            }
    }
}
