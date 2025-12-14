package com.example.flutter_adaptive_assist

import android.content.ContentResolver
import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * FlutterAdaptiveAssistPlugin
 *
 * Provides adaptive accessibility settings to Flutter applications.
 *
 * Supported Android API levels: 21+ (Android 5.0 Lollipop)
 */
class FlutterAdaptiveAssistPlugin : FlutterPlugin, MethodCallHandler {
    companion object {
        private const val TAG = "AdaptiveAssistPlugin"
        private const val CHANNEL_NAME = "flutter_adaptive_assist"

        // Setting keys
        private const val DALTONIZER_ENABLED = "accessibility_display_daltonizer_enabled"
        private const val INVERSION_ENABLED = "accessibility_display_inversion_enabled"
        private const val ANIMATION_SCALE = "animator_duration_scale"
        private const val TRANSITION_SCALE = "transition_animation_scale"
        private const val HIGH_TEXT_CONTRAST = "high_text_contrast_enabled"
        private const val FONT_SCALE = "font_scale"

        // Performance tuning
        private const val NOTIFICATION_DEBOUNCE_MS = 100L
        private val NOTIFICATION_TOKEN = Any()
    }

    private lateinit var channel: MethodChannel
    private var contentResolver: ContentResolver? = null
    private var context: Context? = null
    private var contentObserver: ContentObserver? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        
        context = flutterPluginBinding.applicationContext
        contentResolver = flutterPluginBinding.applicationContext.contentResolver
        
        registerObserver()
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getMonochromeModeEnabled" -> {
                    result.success(isMonochromeModeEnabled())
                }
                "getConfig" -> {
                    result.success(getFullConfig())
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling method call: ${call.method}", e)
            result.error("ERROR", "Failed to execute ${call.method}: ${e.message}", null)
        }
    }

    // Cache for accessibility settings to avoid repeated Settings queries
    private var cachedMonochromeMode: Boolean? = null
    private var cachedReduceMotion: Boolean? = null
    private var cachedHighContrast: Boolean? = null
    private var cachedTextScale: Float? = null
    private var lastCacheTime: Long = 0
    private val cacheValidityMs = 1000L // Cache valid for 1 second

    /**
     * Invalidates the settings cache.
     */
    private fun invalidateCache() {
        cachedMonochromeMode = null
        cachedReduceMotion = null
        cachedHighContrast = null
        cachedTextScale = null
        lastCacheTime = 0
    }

    /**
     * Checks if the cache is still valid.
     */
    private fun isCacheValid(): Boolean {
        return System.currentTimeMillis() - lastCacheTime < cacheValidityMs
    }

    /**
     * Checks if monochrome mode is enabled.
     * This includes color correction (daltonizer) and color inversion.
     */
    private fun isMonochromeModeEnabled(): Boolean {
        // Return cached value if valid
        if (isCacheValid() && cachedMonochromeMode != null) {
            return cachedMonochromeMode!!
        }

        val resolver = contentResolver ?: return false
        
        val result = try {
            val daltonizerEnabled = Settings.Secure.getInt(
                resolver,
                DALTONIZER_ENABLED,
                0
            ) != 0
            
            val inversionEnabled = Settings.Secure.getInt(
                resolver,
                INVERSION_ENABLED,
                0
            ) != 0
            
            daltonizerEnabled || inversionEnabled
        } catch (e: Exception) {
            Log.e(TAG, "Error checking monochrome mode", e)
            false
        }

        cachedMonochromeMode = result
        lastCacheTime = System.currentTimeMillis()
        return result
    }

    /**
     * Checks if reduce motion is enabled.
     * This checks if animation scales are set to 0 or very low values.
     */
    private fun isReduceMotionEnabled(): Boolean {
        // Return cached value if valid
        if (isCacheValid() && cachedReduceMotion != null) {
            return cachedReduceMotion!!
        }

        val resolver = contentResolver ?: return false
        
        val result = try {
            val animatorScale = Settings.Global.getFloat(
                resolver,
                ANIMATION_SCALE,
                1.0f
            )
            
            val transitionScale = Settings.Global.getFloat(
                resolver,
                TRANSITION_SCALE,
                1.0f
            )
            
            // Consider reduce motion enabled if either scale is very low
            animatorScale < 0.1f || transitionScale < 0.1f
        } catch (e: Exception) {
            Log.e(TAG, "Error checking reduce motion", e)
            false
        }

        cachedReduceMotion = result
        lastCacheTime = System.currentTimeMillis()
        return result
    }

    /**
     * Checks if high contrast mode is enabled.
     * Available on Android 5.0+ (API 21)
     */
    private fun isHighContrastEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false
        }

        // Return cached value if valid
        if (isCacheValid() && cachedHighContrast != null) {
            return cachedHighContrast!!
        }
        
        val resolver = contentResolver ?: return false
        
        val result = try {
            Settings.Secure.getInt(
                resolver,
                HIGH_TEXT_CONTRAST,
                0
            ) != 0
        } catch (e: Exception) {
            Log.e(TAG, "Error checking high contrast", e)
            false
        }

        cachedHighContrast = result
        lastCacheTime = System.currentTimeMillis()
        return result
    }

    /**
     * Gets the text scale factor.
     * Returns a value typically between 0.85 and 3.0.
     */
    private fun getTextScaleFactor(): Float {
        // Return cached value if valid
        if (isCacheValid() && cachedTextScale != null) {
            return cachedTextScale!!
        }

        val resolver = contentResolver ?: return 1.0f
        
        val result = try {
            Settings.System.getFloat(
                resolver,
                FONT_SCALE,
                1.0f
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error getting text scale factor", e)
            1.0f
        }

        cachedTextScale = result
        lastCacheTime = System.currentTimeMillis()
        return result
    }

    /**
     * Returns a complete configuration map of all accessibility settings.
     */
    private fun getFullConfig(): Map<String, Any> {
        return mapOf(
            "monochromeModeEnabled" to isMonochromeModeEnabled(),
            "reduceMotionEnabled" to isReduceMotionEnabled(),
            "boldTextEnabled" to false, // Android doesn't have a system-wide bold text setting
            "highContrastEnabled" to isHighContrastEnabled(),
            "textScaleFactor" to getTextScaleFactor().toDouble()
        )
    }

    /**
     * Registers a ContentObserver to listen for accessibility setting changes.
     */
    private fun registerObserver() {
        val resolver = contentResolver ?: run {
            Log.w(TAG, "ContentResolver is null, cannot register observer")
            return
        }

        try {
            val daltonizerUri = Settings.Secure.getUriFor(DALTONIZER_ENABLED)
            val inversionUri = Settings.Secure.getUriFor(INVERSION_ENABLED)

            if (daltonizerUri == null || inversionUri == null) {
                Log.w(TAG, "Unable to get URIs for accessibility settings")
                return
            }

            contentObserver = object : ContentObserver(mainHandler) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    
                    // Invalidate cache when settings change
                    invalidateCache()
                    
                    // Notify Flutter about the change (debounced to avoid rapid-fire updates)
                    mainHandler.removeCallbacksAndMessages(NOTIFICATION_TOKEN)
                    mainHandler.postDelayed({
                        try {
                            val isEnabled = isMonochromeModeEnabled()
                            channel.invokeMethod("onMonochromeModeChange", isEnabled)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error sending monochrome change notification", e)
                        }
                    }, NOTIFICATION_DEBOUNCE_MS, NOTIFICATION_TOKEN)
                }
            }

            resolver.registerContentObserver(daltonizerUri, false, contentObserver!!)
            resolver.registerContentObserver(inversionUri, false, contentObserver!!)
            
            Log.d(TAG, "ContentObserver registered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering ContentObserver", e)
            contentObserver = null
        }
    }

    /**
     * Unregisters the ContentObserver when the plugin is detached.
     */
    private fun unregisterObserver() {
        contentObserver?.let { observer ->
            try {
                contentResolver?.unregisterContentObserver(observer)
                Log.d(TAG, "ContentObserver unregistered")
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering ContentObserver", e)
            }
        }
        contentObserver = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            channel.setMethodCallHandler(null)
            unregisterObserver()
            
            // Clear cache
            invalidateCache()
            
            // Remove any pending callbacks
            mainHandler.removeCallbacksAndMessages(NOTIFICATION_TOKEN)
            
            contentResolver = null
            context = null
            Log.d(TAG, "Plugin detached from engine")
        } catch (e: Exception) {
            Log.e(TAG, "Error during detachment", e)
        }
    }
}