package com.stormlogix.ragetap

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GameSfx.register(flutterEngine.dartExecutor.binaryMessenger, this)
    }

    override fun onDestroy() {
        GameSfx.release()
        super.onDestroy()
    }
}
