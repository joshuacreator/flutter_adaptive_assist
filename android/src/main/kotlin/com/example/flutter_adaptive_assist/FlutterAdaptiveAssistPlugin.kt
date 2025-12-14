package com.example.flutter_adaptive_assist

import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterAdaptiveAssistPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var contentResolver: ContentResolver? = null
    private var contentObserver: ContentObserver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_adaptive_assist")
        channel.setMethodCallHandler(this)
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        registerObserver()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getMonochromeModeEnabled") {
            result.success(isMonochromeModeEnabled())
        } else {
            result.notImplemented()
        }
    }

    private fun isMonochromeModeEnabled(): Boolean {
        val daltonizerEnabled = Settings.Secure.getInt(contentResolver, "accessibility_display_daltonizer_enabled", 0) != 0
        val inversionEnabled = Settings.Secure.getInt(contentResolver, "accessibility_display_inversion_enabled", 0) != 0
        return daltonizerEnabled || inversionEnabled
    }

    private fun registerObserver() {
        val daltonizerUri = Settings.Secure.getUriFor("accessibility_display_daltonizer_enabled")
        val inversionUri = Settings.Secure.getUriFor("accessibility_display_inversion_enabled")

        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                val isEnabled = isMonochromeModeEnabled()
                channel.invokeMethod("onMonochromeModeChange", isEnabled)
            }
        }

        contentResolver?.registerContentObserver(daltonizerUri, false, contentObserver!!)
        contentResolver?.registerContentObserver(inversionUri, false, contentObserver!!)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        contentResolver?.unregisterContentObserver(contentObserver!!)
        contentResolver = null
        contentObserver = null
    }
}
