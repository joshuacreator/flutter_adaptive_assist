package com.example.flutter_adaptive_assist

import android.content.ContentResolver
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.Mockito.`when`
import org.mockito.Mockito.verify
import org.mockito.MockitoAnnotations
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

@RunWith(RobolectricTestRunner::class)
class FlutterAdaptiveAssistPluginTest {

    private lateinit var plugin: FlutterAdaptiveAssistPlugin
    private lateinit var contentResolver: ContentResolver

    @Mock
    private lateinit var mockResult: MethodChannel.Result

    @Before
    fun setUp() {
        MockitoAnnotations.initMocks(this)
        plugin = FlutterAdaptiveAssistPlugin()
        contentResolver = RuntimeEnvironment.application.contentResolver
    }

    @Test
    fun onMethodCall_getMonochromeModeEnabled_returnsTrueWhenDaltonizerEnabled() {
        Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer_enabled", 1)
        Settings.Secure.putInt(contentResolver, "accessibility_display_inversion_enabled", 0)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(true)
    }

    @Test
    fun onMethodCall_getMonochromeModeEnabled_returnsTrueWhenInversionEnabled() {
        Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer_enabled", 0)
        Settings.Secure.putInt(contentResolver, "accessibility_display_inversion_enabled", 1)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(true)
    }

    @Test
    fun onMethodCall_getMonochromeModeEnabled_returnsFalseWhenBothDisabled() {
        Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer_enabled", 0)
        Settings.Secure.putInt(contentResolver, "accessibility_display_inversion_enabled", 0)

        val call = MethodCall("getMonochromeModeEnabled", null)
        plugin.onMethodCall(call, mockResult)

        verify(mockResult).success(false)
    }
}
