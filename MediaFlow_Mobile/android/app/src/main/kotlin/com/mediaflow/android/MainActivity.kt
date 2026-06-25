package com.mediaflow.android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PythonBridge.getInstance(applicationContext).initialize(flutterEngine)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        PythonBridge.getInstance(applicationContext).destroy()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
