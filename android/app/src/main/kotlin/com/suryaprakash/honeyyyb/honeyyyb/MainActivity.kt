package com.suryaprakash.honeyyyb.honeyyyb

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val FILE_PICKER_CHANNEL = "com.suryaprakash.honeyyyb/file_picker"
    private val SMS_CHANNEL = "com.suryaprakash.honeyyyb/sms_reader"
    private val NOTIF_CHANNEL = "com.suryaprakash.honeyyyb/notifications"
    private val NOTIF_EVENT_CHANNEL = "com.suryaprakash.honeyyyb/notification_stream"
    private val TTS_CHANNEL = "com.suryaprakash.honeyyyb/tts"

    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingSmsPermissionResult: MethodChannel.Result? = null
    private val PICK_PDF_REQUEST = 1001
    private val SMS_PERMISSION_REQUEST = 1002

    private var tts: TextToSpeech? = null
    private var ttsInitialized = false
    private var eventSink: EventChannel.EventSink? = null
    private var notificationReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Android TextToSpeech Engine
        tts = TextToSpeech(this, this)

        // Native TTS Channel (Human Voice Speech)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val pitch = (call.argument<Double>("pitch") ?: 1.1).toFloat()
                    val rate = (call.argument<Double>("rate") ?: 0.95).toFloat()

                    if (ttsInitialized && tts != null && text.isNotEmpty()) {
                        tts?.setPitch(pitch)
                        tts?.setSpeechRate(rate)
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "HONEY_AI_VOICE")
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stop" -> {
                    tts?.stop()
                    result.success(true)
                }
                "isAvailable" -> {
                    result.success(ttsInitialized)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Native PDF File Picker
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_PICKER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickPdf") {
                pendingFileResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/pdf"
                }
                startActivityForResult(intent, PICK_PDF_REQUEST)
            } else {
                result.notImplemented()
            }
        }

        // Native Android SMS Reader & Runtime Permission Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED) {
                        result.success(true)
                    } else {
                        pendingSmsPermissionResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.READ_SMS), SMS_PERMISSION_REQUEST)
                    }
                }
                "getSmsMessages" -> {
                    try {
                        val sinceEpoch = call.argument<Long>("sinceEpoch") ?: 0L
                        val smsList = ArrayList<Map<String, Any?>>()

                        val uri = Uri.parse("content://sms/inbox")
                        val projection = arrayOf("_id", "address", "body", "date")
                        val selection = if (sinceEpoch > 0) "date >= ?" else null
                        val selectionArgs = if (sinceEpoch > 0) arrayOf(sinceEpoch.toString()) else null
                        val sortOrder = "date DESC"

                        contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
                            val idIdx = cursor.getColumnIndex("_id")
                            val addressIdx = cursor.getColumnIndex("address")
                            val bodyIdx = cursor.getColumnIndex("body")
                            val dateIdx = cursor.getColumnIndex("date")

                            while (cursor.moveToNext()) {
                                val msg = HashMap<String, Any?>()
                                if (idIdx != -1) msg["id"] = cursor.getString(idIdx)
                                if (addressIdx != -1) msg["address"] = cursor.getString(addressIdx)
                                if (bodyIdx != -1) msg["body"] = cursor.getString(bodyIdx)
                                if (dateIdx != -1) msg["date"] = cursor.getLong(dateIdx)
                                smsList.add(msg)
                            }
                        }

                        result.success(smsList)
                    } catch (e: Exception) {
                        result.error("SMS_QUERY_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Live GPay / PhonePe Notification Detection Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerEnabled" -> {
                    val packageNames = NotificationManagerCompat.getEnabledListenerPackages(this)
                    val isEnabled = packageNames.contains(packageName)
                    result.success(isEnabled)
                }
                "openListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "getCapturedNotifications" -> {
                    val list = ArrayList(HoneyNotificationListenerService.capturedNotifications)
                    HoneyNotificationListenerService.capturedNotifications.clear()
                    result.success(list)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Live Notification Real-time Stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIF_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    HoneyNotificationListenerService.notificationCallback = { notif ->
                        runOnUiThread {
                            eventSink?.success(notif)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    HoneyNotificationListenerService.notificationCallback = null
                }
            }
        )
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("en", "IN")
            ttsInitialized = true
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingSmsPermissionResult?.success(granted)
            pendingSmsPermissionResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_PDF_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null && data.data != null) {
                val uri: Uri = data.data!!
                try {
                    var fileName = "Statement.pdf"
                    contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                        val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (nameIndex != -1 && cursor.moveToFirst()) {
                            fileName = cursor.getString(nameIndex)
                        }
                    }

                    val inputStream = contentResolver.openInputStream(uri)
                    val bytes = inputStream?.readBytes()
                    inputStream?.close()

                    if (bytes != null) {
                        val resultMap = HashMap<String, Any>()
                        resultMap["name"] = fileName
                        resultMap["bytes"] = bytes
                        pendingFileResult?.success(resultMap)
                    } else {
                        pendingFileResult?.error("FILE_READ_ERROR", "Could not read bytes from PDF", null)
                    }
                } catch (e: Exception) {
                    pendingFileResult?.error("FILE_PICKER_ERROR", e.message, null)
                }
            } else {
                pendingFileResult?.success(null)
            }
            pendingFileResult = null
        }
    }

    override fun onDestroy() {
        if (tts != null) {
            tts?.stop()
            tts?.shutdown()
        }
        super.onDestroy()
    }
}
