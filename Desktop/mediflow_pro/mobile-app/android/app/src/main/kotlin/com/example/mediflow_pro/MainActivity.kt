package com.example.mediflow_pro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL = "deep_link_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val intentData = getIntentData()
                    result.success(intentData)
                }
                "getIntentLink" -> {
                    val intentData = getIntentData()
                    result.success(intentData)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getIntentData(): String? {
        val intent: Intent = this.getIntent()
        val data: Uri? = intent.data
        return data?.toString()
    }
}