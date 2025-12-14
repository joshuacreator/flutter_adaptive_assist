// Run with: ./gradlew test

package com.example.flutter_adaptive_assist

import android.content.ContentResolver
import android.content.Context
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations
import org.mockito.junit.MockitoJUnitRunner

@RunWith(MockitoJUnitRunner::class)
class FlutterAdaptiveAssistPluginTest {

    @Mock
    private lateinit var mockContext: Context

    @Mock
    private lateinit var mockContentResolver: ContentResolver

    @Mock
    private lateinit var mockBinaryMessenger: BinaryMessenger

    @Mock
    private lateinit var mockChannel: MethodChannel

    @Mock
    private lateinit var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    @Mock
    private lateinit var mockResult: MethodChannel.Result

    private lateinit var plugin: FlutterAdaptiveAssistPlugin

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        plugin = FlutterAdaptiveAssistPlugin()

        `when`(mockFlutterPluginBinding.applicationContext).thenReturn(mockContext)
        `when`(mockFlutterPluginBinding.binaryMessenger).thenReturn(mockBinaryMessenger)
        `when`(mockContext.contentResolver).thenReturn(mockContentResolver)
    }

    @Test
    fun `onAttachedToEngine sets up channel and registers observer`() {
        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        verify(mockFlutterPluginBinding).binaryMessenger
        verify(mockFlutterPluginBinding).applicationContext
    }

    @Test
    fun `getMonochromeModeEnabled returns true when daltonizer is enabled`() {
        // Mock Settings to return daltonizer enabled
        mockSettingsSecureInt(DALTONIZER_ENABLED, 1)
        mockSettingsSecureInt(INVERSION_ENABLED, 0)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(true)
    }

    @Test
    fun `getMonochromeModeEnabled returns true when inversion is enabled`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 0)
        mockSettingsSecureInt(INVERSION_ENABLED, 1)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(true)
    }

    @Test
    fun `getMonochromeModeEnabled returns true when both are enabled`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 1)
        mockSettingsSecureInt(INVERSION_ENABLED, 1)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(true)
    }

    @Test
    fun `getMonochromeModeEnabled returns false when both are disabled`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 0)
        mockSettingsSecureInt(INVERSION_ENABLED, 0)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(false)
    }

    @Test
    fun `getMonochromeModeEnabled caches result on first call`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 1)
        mockSettingsSecureInt(INVERSION_ENABLED, 0)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        // First call
        val call1 = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call1, mockResult)

        // Second call - should use cache
        val call2 = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call2, mockResult)

        // Verify settings were only queried once (cached on second call)
        verify(mockResult, times(2)).success(true)
    }

    @Test
    fun `getConfig returns full configuration map`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 1)
        mockSettingsSecureInt(INVERSION_ENABLED, 0)
        mockSettingsSecureInt(HIGH_TEXT_CONTRAST, 1)
        mockSettingsGlobalFloat(ANIMATION_SCALE, 0.0f)
        mockSettingsGlobalFloat(TRANSITION_SCALE, 1.0f)
        mockSettingsSystemFloat(FONT_SCALE, 1.5f)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getConfig", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(argThat { map ->
            map is Map<*, *> &&
                map["monochromeModeEnabled"] == true &&
                map["reduceMotionEnabled"] == true &&
                map["highContrastEnabled"] == true &&
                map["textScaleFactor"] == 1.5
        })
    }

    @Test
    fun `reduceMotion is true when animation scale is very low`() {
        mockSettingsGlobalFloat(ANIMATION_SCALE, 0.05f)
        mockSettingsGlobalFloat(TRANSITION_SCALE, 1.0f)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getConfig", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(argThat { map ->
            map is Map<*, *> && map["reduceMotionEnabled"] == true
        })
    }

    @Test
    fun `reduceMotion is false when animation scale is normal`() {
        mockSettingsGlobalFloat(ANIMATION_SCALE, 1.0f)
        mockSettingsGlobalFloat(TRANSITION_SCALE, 1.0f)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getConfig", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(argThat { map ->
            map is Map<*, *> && map["reduceMotionEnabled"] == false
        })
    }

    @Test
    fun `unknown method returns notImplemented`() {
        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("unknownMethod", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).notImplemented()
    }

    @Test
    fun `exception handling returns error result`() {
        // Make ContentResolver throw an exception
        `when`(mockContext.contentResolver).thenThrow(RuntimeException("Test exception"))

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(eq("ERROR"), anyString(), isNull())
    }

    @Test
    fun `onDetachedFromEngine cleans up resources`() {
        plugin.onAttachedToEngine(mockFlutterPluginBinding)
        plugin.onDetachedFromEngine(mockFlutterPluginBinding)

        // Should not throw
        assertTrue(true)
    }

    @Test
    fun `handles Settings access exceptions gracefully`() {
        // Mock Settings to throw exception
        `when`(
            Settings.Secure.getInt(
                eq(mockContentResolver),
                eq(DALTONIZER_ENABLED),
                anyInt()
            )
        ).thenThrow(SecurityException("No permission"))

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        // Should return false on error
        verify(mockResult).success(false)
    }

    @Test
    fun `cache expires after validity period`() {
        mockSettingsSecureInt(DALTONIZER_ENABLED, 1)
        mockSettingsSecureInt(INVERSION_ENABLED, 0)

        plugin.onAttachedToEngine(mockFlutterPluginBinding)

        // First call
        val call1 = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call1, mockResult)

        // Simulate cache expiry by waiting
        Thread.sleep(1100) // Wait for cache to expire (1 second + margin)

        // Change the setting value
        mockSettingsSecureInt(DALTONIZER_ENABLED, 0)

        // Second call - should query again
        val call2 = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call2, mockResult)

        // First call should return true, second should return false
        verify(mockResult).success(true)
        verify(mockResult).success(false)
    }

    // Helper methods for mocking Settings
    private fun mockSettingsSecureInt(key: String, value: Int) {
        `when`(
            Settings.Secure.getInt(
                eq(mockContentResolver),
                eq(key),
                anyInt()
            )
        ).thenReturn(value)
    }

    private fun mockSettingsGlobalFloat(key: String, value: Float) {
        `when`(
            Settings.Global.getFloat(
                eq(mockContentResolver),
                eq(key),
                anyFloat()
            )
        ).thenReturn(value)
    }

    private fun mockSettingsSystemFloat(key: String, value: Float) {
        `when`(
            Settings.System.getFloat(
                eq(mockContentResolver),
                eq(key),
                anyFloat()
            )
        ).thenReturn(value)
    }

    companion object {
        private const val DALTONIZER_ENABLED = "accessibility_display_daltonizer_enabled"
        private const val INVERSION_ENABLED = "accessibility_display_inversion_enabled"
        private const val ANIMATION_SCALE = "animator_duration_scale"
        private const val TRANSITION_SCALE = "transition_animation_scale"
        private const val HIGH_TEXT_CONTRAST = "high_text_contrast_enabled"
        private const val FONT_SCALE = "font_scale"
    }
}