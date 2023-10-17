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
import io.dolphin.move.MoveConfig
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
    private lateinit var configChangeChannel: EventChannel
    private lateinit var tripStartChannel: EventChannel
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
        configChangeChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-configChange").also {
                it.setStreamHandler(ConfigChangeStreamHandler())
            }
        tripStartChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-tripStart").also {
                it.setStreamHandler(TripStartStreamHandler())
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

    companion object {
        private const val ERROR_SCAN_DEVICES: String = "SCAN_DEVICES"
    }

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

        if (filters.contains(MoveDeviceFilter.PAIRED.filter)) {
            proceedWithPairedDevices()
        }
        if (filters.contains(MoveDeviceFilter.BEACON.filter)) {
            proceedWithBleDevices()
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

    @SuppressLint("MissingPermission")
    private fun proceedWithPairedDevices() {
        val hasFeature =
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
        if (!hasFeature) {
            events?.error(ERROR_SCAN_DEVICES, "Missing FEATURE_BLUETOOTH_LE", null)
            return
        }
        val bluetoothManager: BluetoothManager? =
            context.getSystemService(BluetoothManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_CONNECT)) {
                events?.error(ERROR_SCAN_DEVICES, "Missing BLUETOOTH_CONNECT permission", null)
                return
            }
        }
        val bondedDevices = bluetoothManager?.adapter?.bondedDevices
            ?.mapNotNull { MoveSdk.get()?.convertToMoveDevice(it) }.orEmpty()
        discoveredDevices.addAll(bondedDevices)
        uiThreadHandler.post {
            events?.success(bondedDevices.toMoveDeviceObjectList())
        }
    }

    @SuppressLint("MissingPermission") // covered with isPermissionGranted
    private fun proceedWithBleDevices() {
        val bluetoothManager: BluetoothManager? =
            context.getSystemService(BluetoothManager::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_SCAN)) {
                events?.error(ERROR_SCAN_DEVICES, "Missing BLUETOOTH_SCAN permission", null)
                return
            }
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_CONNECT)) {
                events?.error(ERROR_SCAN_DEVICES, "Missing BLUETOOTH_CONNECT permission", null)
                return
            }
        }
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
            if (!isPermissionGranted(Manifest.permission.ACCESS_FINE_LOCATION)) {
                events?.error(ERROR_SCAN_DEVICES, "Missing ACCESS_FINE_LOCATION permission", null)
                return
            }
            if (!isPermissionGranted(Manifest.permission.BLUETOOTH_ADMIN)) {
                events?.error(ERROR_SCAN_DEVICES, "Missing BLUETOOTH_ADMIN permission", null)
                return
            }
        }
        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R || Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            if (!isPermissionGranted(Manifest.permission.ACCESS_BACKGROUND_LOCATION)) {
                events?.error(
                    ERROR_SCAN_DEVICES,
                    "Missing ACCESS_BACKGROUND_LOCATION permission",
                    null
                )
                return
            }
        }
        if (bluetoothManager?.adapter?.isEnabled == false) {
            events?.error(ERROR_SCAN_DEVICES, "Please turn on bluetooth", null)
            return
        }
        val hasFeature =
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
        if (!hasFeature) {
            events?.error(ERROR_SCAN_DEVICES, "Missing FEATURE_BLUETOOTH_LE", null)
            return
        }
        bluetoothManager?.adapter?.bluetoothLeScanner?.startScan(leCallback)
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return try {
            ContextCompat.checkSelfPermission(
                context,
                permission
            ) == PackageManager.PERMISSION_GRANTED
        } catch (e: Exception) {
            false
        }
    }

    enum class MoveDeviceFilter(val filter: String) {
        BEACON("beacon"),
        PAIRED("paired");
    }
}


class ConfigChangeStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setRemoteConfigChangeListener(
            object : MoveSdk.RemoteConfigChangeListener {
                override fun onConfigChanged(config: MoveConfig) {
                    uiThreadHandler.post {
                        events?.success(config.toMoveConfigList())
                    }
                }
            }
        )
    }

    override fun onCancel(arguments: Any?) {
    }
}

class TripStartStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setTripStartListener(
            object : MoveSdk.TripStartListener {
                override fun onTripStarted(startDate: Date) {
                    uiThreadHandler.post {
                        events?.success(startDate.time)
                    }
                }
            }
        )
    }

    override fun onCancel(arguments: Any?) {
    }
}
