package com.nexora.audio

import android.media.audiofx.Equalizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "nexora/equalizer"
    }

    private var equalizer: Equalizer? = null
    private var sessionId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "apply") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    applyEqualizer(call)
                    result.success(true)
                } catch (error: Exception) {
                    releaseEqualizer()
                    result.error("EQ_UNAVAILABLE", error.message, null)
                }
            }
    }

    private fun applyEqualizer(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: true
        val requestedSession = call.argument<Int>("sessionId")
        if (requestedSession == null || requestedSession <= 0) {
            releaseEqualizer()
            return
        }
        if (requestedSession != sessionId) {
            releaseEqualizer()
            equalizer = Equalizer(0, requestedSession).also { it.enabled = enabled }
            sessionId = requestedSession
        }

        val current = equalizer ?: return
        val frequencies = call.argument<List<Number>>("frequencies") ?: emptyList()
        val gains = call.argument<List<Number>>("gains") ?: emptyList()
        val range = current.bandLevelRange
        for (band in 0 until current.numberOfBands.toInt()) {
            val nativeFrequencyHz = current.getCenterFreq(band.toShort()) / 1000f
            val sourceIndex = frequencies.indices.minByOrNull { index ->
                kotlin.math.abs(frequencies[index].toFloat() - nativeFrequencyHz)
            } ?: continue
            if (sourceIndex >= gains.size) continue
            val targetMillibels = (gains[sourceIndex].toFloat() * 100f).toInt()
            val clamped = targetMillibels.coerceIn(range[0].toInt(), range[1].toInt())
            current.setBandLevel(band.toShort(), clamped.toShort())
        }
        // Android's Equalizer has no preamp control; the requested preamp is
        // accepted by the bridge but cannot be applied through this API.
        current.enabled = enabled
    }

    private fun releaseEqualizer() {
        equalizer?.release()
        equalizer = null
        sessionId = null
    }

    override fun onDestroy() {
        releaseEqualizer()
        super.onDestroy()
    }
}
