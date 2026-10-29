package vn.urani.noisemeter

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AudioEffect
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Raw microphone capture for the Dart `PlatformMicSource`.
 *
 * Prefers [MediaRecorder.AudioSource.UNPROCESSED] (no AGC, no noise
 * suppression, flat response) and falls back to VOICE_RECOGNITION, whose
 * CDD requirements also forbid AGC. Any effects the device still attaches
 * are explicitly disabled.
 */
class MicStreamHandler(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "vn.urani.noisemeter/mic"
        private const val EVENT_CHANNEL = "vn.urani.noisemeter/mic/samples"
        private const val PERMISSION_REQUEST_CODE = 4107
        private val SAMPLE_RATES = intArrayOf(48_000, 44_100)
        private const val READ_FRAMES = 4096
        private const val READER_JOIN_TIMEOUT_MS = 500L
    }

    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var recorder: AudioRecord? = null
    private var readerThread: Thread? = null
    private var audioSourceName = ""
    private val effects = mutableListOf<AudioEffect>()

    @Volatile
    private var capturing = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "start" -> start(result)
            "stop" -> {
                stopCapture()
                result.success(null)
            }
            "openSettings" -> {
                activity.startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", activity.packageName, null),
                    ),
                )
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopCapture()
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST_CODE) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    fun dispose() {
        stopCapture()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        pendingPermissionResult?.error("disposed", "Activity destroyed", null)
        pendingPermissionResult = null
    }

    private fun hasPermission() =
        activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_pending", "A permission request is already open", null)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            PERMISSION_REQUEST_CODE,
        )
    }

    private fun start(result: MethodChannel.Result) {
        if (!hasPermission()) {
            result.error("permission_denied", "RECORD_AUDIO not granted", null)
            return
        }
        if (!capturing) {
            val errorCode = startCapture()
            if (errorCode != null) {
                result.error(errorCode, "AudioRecord could not start", null)
                return
            }
        }
        val record = recorder ?: return result.error("start_failed", "AudioRecord missing", null)
        result.success(
            mapOf(
                "sampleRate" to record.sampleRate.toDouble(),
                "audioSource" to audioSourceName,
            ),
        )
    }

    /** Returns an error code for the Dart side, or null once capture is running. */
    private fun startCapture(): String? {
        val audioManager = activity.getSystemService(AudioManager::class.java)
        val unprocessed = audioManager?.getProperty(
            AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED,
        ) == "true"
        val source =
            if (unprocessed) MediaRecorder.AudioSource.UNPROCESSED
            else MediaRecorder.AudioSource.VOICE_RECOGNITION
        audioSourceName = if (unprocessed) "UNPROCESSED" else "VOICE_RECOGNITION"

        val record = createRecorder(source) ?: return "start_failed"
        disableEffects(record.audioSessionId)
        record.startRecording()
        if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
            releaseRecorder(record)
            return "mic_busy"
        }
        recorder = record
        capturing = true
        readerThread = Thread({ readLoop(record) }, "MicStreamReader").also { it.start() }
        return null
    }

    @Suppress("MissingPermission") // Checked by start() before calling here.
    private fun createRecorder(source: Int): AudioRecord? {
        for (rate in SAMPLE_RATES) {
            val minBytes = AudioRecord.getMinBufferSize(
                rate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT,
            )
            if (minBytes <= 0) continue
            val record = AudioRecord(
                source,
                rate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT,
                maxOf(minBytes, READ_FRAMES * Float.SIZE_BYTES * 2),
            )
            if (record.state == AudioRecord.STATE_INITIALIZED) return record
            record.release()
        }
        return null
    }

    private fun disableEffects(sessionId: Int) {
        if (AutomaticGainControl.isAvailable()) {
            AutomaticGainControl.create(sessionId)?.let { effects += it }
        }
        if (NoiseSuppressor.isAvailable()) {
            NoiseSuppressor.create(sessionId)?.let { effects += it }
        }
        if (AcousticEchoCanceler.isAvailable()) {
            AcousticEchoCanceler.create(sessionId)?.let { effects += it }
        }
        effects.forEach { it.enabled = false }
    }

    private fun readLoop(record: AudioRecord) {
        val buffer = FloatArray(READ_FRAMES)
        while (capturing) {
            val read = record.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)
            when {
                read > 0 -> {
                    val chunk = buffer.copyOf(read)
                    mainHandler.post { eventSink?.success(chunk) }
                }
                read < 0 && capturing -> {
                    mainHandler.post {
                        eventSink?.error("read_failed", "AudioRecord.read() = $read", null)
                        stopCapture()
                    }
                    return
                }
            }
        }
    }

    private fun stopCapture() {
        val record = recorder ?: return
        capturing = false
        record.stop() // Unblocks the reader's pending read().
        readerThread?.join(READER_JOIN_TIMEOUT_MS)
        readerThread = null
        releaseRecorder(record)
        recorder = null
    }

    private fun releaseRecorder(record: AudioRecord) {
        effects.forEach { it.release() }
        effects.clear()
        record.release()
    }
}
