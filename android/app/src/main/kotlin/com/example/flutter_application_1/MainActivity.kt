package com.example.flutter_application_1

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * Flutter port of the Cordova "cordova-plugin-scanner" (ScannerPlugin).
 *
 * The hardware scanner broadcasts an Android Intent:
 *   action : android.decode.scan_result
 *   extra  : code_data  (raw scan string)
 *
 * This activity registers a BroadcastReceiver for that action and streams
 * every scan result to Dart over an EventChannel ("cordova/scanner").
 * Equivalent to the Cordova plugin's startListening()/stopListening().
 */
class MainActivity : FlutterActivity() {

    private val channelName = "cordova/scanner"
    private val actionScanResult = "android.decode.scan_result"
    private val actionScanExtra = "code_data"

    private var eventSink: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerScanReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterScanReceiver()
                    eventSink = null
                }
            })
    }

    private fun registerScanReceiver() {
        if (scanReceiver != null) return
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == actionScanResult) {
                    val scanData = intent.getStringExtra(actionScanExtra)
                    if (!scanData.isNullOrEmpty()) {
                        eventSink?.success(scanData)
                    }
                }
            }
        }
        val filter = IntentFilter(actionScanResult)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ needs an explicit exported flag. The scan result
            // comes from another app (the scanner service) => EXPORTED.
            registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(scanReceiver, filter)
        }
    }

    private fun unregisterScanReceiver() {
        scanReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        scanReceiver = null
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        super.onDestroy()
    }
}
