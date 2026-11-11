package com.example.v_browser

import android.media.MediaScannerConnection
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: AudioServiceActivity() {
    private val channelName = "com.example.v_browser/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        val file = File(path)
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(file.absolutePath),
                            null
                        ) { _, _ -> }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCAN_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "Path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
