package com.movesdk

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.dolphin.move.MoveAuthState
import io.dolphin.move.MoveDevice
import io.dolphin.move.MoveScanResult
import io.dolphin.move.MoveSdk
import io.dolphin.move.MoveSdkState
import io.dolphin.move.MoveServiceFailure
import io.dolphin.move.MoveServiceWarning
import io.dolphin.move.MoveTripState
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.nio.ByteBuffer
import java.util.*

/** MoveSdkPlugin */
class MoveSdkPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var authStateChannel: EventChannel
    private lateinit var sdkStateChannel: EventChannel
    private lateinit var tripStateChannel: EventChannel
    private lateinit var serviceErrorChannel: EventChannel
    private lateinit var serviceWarningChannel: EventChannel
    private lateinit var sdkLogChannel: EventChannel
    private lateinit var deviceDiscoveryChannel: EventChannel
    private lateinit var deviceScanChannel: EventChannel
    private var context: Context? = null // Instance variable for context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "movesdk")
        channel.setMethodCallHandler(this)
        /**
         * [MoveSdk.AuthStateUpdateListener], [MoveSdk.TripStateListener],
         * [MoveSdk.StateListener], [MoveSdk.MoveErrorListener], [MoveSdk.MoveWarningListener]
         * implemented using [EventChannel] and don't have implementation in [MoveSdkFlutterAdapter]
         */
        sdkStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-sdkState").also {
                it.setStreamHandler(SdkStateStreamHandler())
            }
        tripStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-tripState").also {
                it.setStreamHandler(TripStateStreamHandler())
            }
        authStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-authState").also {
                it.setStreamHandler(AuthStateStreamHandler())
            }
        serviceErrorChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-serviceError").also {
                it.setStreamHandler(ServiceErrorStreamHandler())
            }
        serviceWarningChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-serviceWarning").also {
                it.setStreamHandler(ServiceWarningStreamHandler())
            }
        sdkLogChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-log").also {
                it.setStreamHandler(LogStreamHandler())
            }
        deviceDiscoveryChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-deviceDiscovery").also {
                it.setStreamHandler(DeviceDiscoveryStreamHandler())
            }
        deviceScanChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-deviceScanner").also {
                it.setStreamHandler(DeviceScanningStreamHandler(flutterPluginBinding.applicationContext))
            }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        context?.let {
            val flutterAdapter = MoveSdkFlutterAdapter(it, call, result)
            val method = flutterAdapter::class.java.methods
                .find { method -> method.name == call.method }
            if (method != null) {
                method.invoke(flutterAdapter)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

class SdkStateStreamHandler : EventChannel.StreamHandler {

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        events?.success(MoveSdk.get()?.getSdkState()?.name)
        MoveSdk.get()?.sdkStateListener(object : MoveSdk.StateListener {
            override fun onStateChanged(sdk: MoveSdk, state: MoveSdkState) {
                uiThreadHandler.post {
                    events?.success(state.name)
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class TripStateStreamHandler : EventChannel.StreamHandler {

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        events?.success(MoveSdk.get()?.getTripState()?.name)
        MoveSdk.get()?.tripStateListener(object : MoveSdk.TripStateListener {
            override fun onTripStateChanged(tripState: MoveTripState) {
                uiThreadHandler.post {
                    events?.success(tripState.name)
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class AuthStateStreamHandler : EventChannel.StreamHandler {

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        events?.success(MoveSdk.get()?.getAuthState()?.name)
        MoveSdk.get()?.authStateUpdateListener(object : MoveSdk.AuthStateUpdateListener {
            override fun onAuthStateUpdate(state: MoveAuthState) {
                uiThreadHandler.post {
                    events?.success(state.name)
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class ServiceErrorStreamHandler : EventChannel.StreamHandler {

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        MoveSdk.get()?.setServiceErrorListener(object : MoveSdk.MoveErrorListener {
            override fun onMoveError(serviceFailures: List<MoveServiceFailure>) {
                uiThreadHandler.post {
                    events?.success(serviceFailures.toErrorObject())
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class ServiceWarningStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setServiceWarningListener(object : MoveSdk.MoveWarningListener {
            override fun onMoveWarning(serviceWarnings: List<MoveServiceWarning>) {
                uiThreadHandler.post {
                    events?.success(serviceWarnings.toWarningObject())
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class LogStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setLogListener(object : MoveSdk.MoveLogCallback {
            override fun onLogReceived(eventName: String, value: String?) {
                uiThreadHandler.post {
                    events?.success(eventName)
                }
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }
}

class DeviceDiscoveryStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.deviceDiscoveryListener(
            object : MoveSdk.DeviceDiscoveryListener {
                override fun onScanResult(results: List<MoveScanResult>) {
                    uiThreadHandler.post {
                        events?.success(results.toScanResultObjectList())
                    }
                }
            }
        )
    }

    override fun onCancel(arguments: Any?) {
    }
}

class DeviceScanningStreamHandler(
    private val context: Context,
) : EventChannel.StreamHandler {

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
    private var events: EventChannel.EventSink? = null
    private val discoveredDevices = mutableSetOf<MoveDevice>()
    private var proximityId: String? = null
    private var manufacturerId: Int? = null

    private val leCallback = object : ScanCallback() {
        @SuppressLint("MissingPermission")
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            if (proximityId != null && manufacturerId != null) {
                val manufacturerSpecificDataId =
                    manufacturerId?.let { result.scanRecord?.getManufacturerSpecificData(it) }
                val uuid = getProximityUUID(manufacturerSpecificDataId)
                if (uuid.isNullOrEmpty() || !uuid.equals(proximityId, true)) return
            }
            val device = MoveSdk.get()?.convertToMoveDevice(result) ?: return
            if (!discoveredDevices.contains(device)) {
                discoveredDevices.add(device)
                uiThreadHandler.post {
                    events?.success(listOf(device).toMoveDeviceObjectList())
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_SCAN,
                ) != PackageManager.PERMISSION_GRANTED
            ) return
            if (
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_CONNECT,
                ) != PackageManager.PERMISSION_GRANTED
            ) return
        }
        val filters = mutableListOf<String>()
        (arguments as? Map<String, Any>)?.let {
            manufacturerId = it["manufacturerId"] as? Int
            proximityId = it["uuid"] as? String
            (it["filter"] as? ArrayList<String>)?.let(filters::addAll)
        }
        discoveredDevices.clear()
        this.events = events
        val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
        if (filters.contains(MoveDeviceFilter.PAIRED.filter)) {
            val bondedDevices = bluetoothManager.adapter.bondedDevices
                .mapNotNull { MoveSdk.get()?.convertToMoveDevice(it) }
            discoveredDevices.addAll(bondedDevices)
            uiThreadHandler.post {
                events?.success(bondedDevices.toMoveDeviceObjectList())
            }
        }
        if (filters.contains(MoveDeviceFilter.BEACON.filter)) {
            bluetoothManager.adapter.bluetoothLeScanner.startScan(leCallback)
        }
    }

    @SuppressLint("MissingPermission")
    override fun onCancel(arguments: Any?) {
        events = null
        proximityId = null
        manufacturerId = null
        val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
        bluetoothManager.adapter.bluetoothLeScanner.stopScan(leCallback)
    }

    private fun getProximityUUID(manufacturerSpecificData: ByteArray?): String? {
        if (manufacturerSpecificData == null || manufacturerSpecificData.size < 23) {
            return null
        }
        val resultBuffer = ByteBuffer.wrap(manufacturerSpecificData)
        val uuidA = resultBuffer.getLong(2)
        val uuidB = resultBuffer.getLong(10)
        val uuid = UUID(uuidA, uuidB)
        return uuid.toString().uppercase(Locale.getDefault())
    }

    enum class MoveDeviceFilter(val filter: String) {
        BEACON("beacon"),
        PAIRED("paired");
    }
}




