package com.movesdk

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.permission.HealthPermission.Companion.PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND
import androidx.health.connect.client.records.StepsRecord
import io.dolphin.move.MoveAuthState
import io.dolphin.move.MoveConfig
import io.dolphin.move.MoveDevice
import io.dolphin.move.MoveHealthScore
import io.dolphin.move.MoveScanResult
import io.dolphin.move.MoveSdk
import io.dolphin.move.MoveSdkState
import io.dolphin.move.MoveServiceFailure
import io.dolphin.move.MoveServiceWarning
import io.dolphin.move.MoveTripState
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.util.Date
import java.util.Locale
import java.util.UUID

/** MoveSdkPlugin */
class MoveSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "MoveSdkPlugin"
    }

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
    private lateinit var deviceStateChannel: EventChannel
    private lateinit var healthListenerChannel: EventChannel
    private var context: Context? = null // Instance variable for context

    private val mainScope = CoroutineScope(Dispatchers.Main)

    private val allHealthPermissions =
        setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            PERMISSION_READ_HEALTH_DATA_IN_BACKGROUND,
        )
    private val android14Permissions =
        setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
        )
    val requestPermissionActivityContract =
        PermissionController.createRequestPermissionResultContract()

    var requestPermissions: ActivityResultLauncher<Set<String>>? = null
    var healthPermissionsResult: MethodChannel.Result? = null

    /// Plugin registration.
    /// - Parameters:
    ///   - flutterPluginBinding: Flutter plugin binding.
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
                it.setStreamHandler(SdkStateStreamHandler(mainScope))
            }
        tripStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-tripState").also {
                it.setStreamHandler(TripStateStreamHandler())
            }
        authStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-authState").also {
                it.setStreamHandler(AuthStateStreamHandler(mainScope))
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
        deviceStateChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-deviceState").also {
                it.setStreamHandler(DeviceStateStreamHandler())
            }
        healthListenerChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "movesdk-sdkHealth").also {
                it.setStreamHandler(HealthListenerStreamHandler())
            }
    }

    /// Method call handler.
    /// - Parameters:
    ///   - call: [MethodCall].
    ///   - result: A [MethodChannel.Result] used for submitting the result of the call.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        context?.let {
            if (call.method == "requestHealthPermissions") {
                try {
                    healthPermissionsResult = result
                    requestPermissions?.launch(allHealthPermissions)
                    Log.i(TAG, "requestHealthPermissions: $requestPermissions")
                } catch (e: ActivityNotFoundException) {
                    Log.i(TAG, "Activity Not Found: $e")
                    result.error("", e.message, null)
                } catch (e: Exception) {
                    Log.i(TAG, "Exception requesting permissions for Health Connect: $e")
                    result.error("", e.message, null)
                }
            } else {
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
    }

    /// On detached from engine.
    /// - Parameters:
    ///   - binding: Flutter plugin binding.
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "Attached To Activity")
        requestPermissions = (binding.activity as? ComponentActivity)?.registerForActivityResult(
            requestPermissionActivityContract
        ) { granted ->
            val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                android14Permissions
            } else {
                allHealthPermissions
            }
            if (granted.containsAll(permissions)) {
                Log.i(TAG, "Health connect permission has been granted")
                MoveSdk.get()?.resolveError()
                healthPermissionsResult?.success(true)
            } else {
                Log.i(TAG, "Health connect permission NOT granted")
                healthPermissionsResult?.error("", "Health connect permission NOT granted", null)
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i(TAG, "Detached From Activity For Config Changes")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i(TAG, "Reattached To Activity For Config Changes")
    }

    override fun onDetachedFromActivity() {
        Log.i(TAG, "Detached From Activity")
    }
}

/// SDK state handler.
class SdkStateStreamHandler(
    private val coroutineScope: CoroutineScope,
) : EventChannel.StreamHandler {

    private val ioContext = Dispatchers.IO

    /// Handler for UI thread.
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for SDK state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        coroutineScope.launch {
            val state = withContext(ioContext) {
                MoveSdk.get()?.getSdkState()?.name ?: MoveSdkState.Uninitialised.name
            }
            events?.success(state)
            MoveSdk.get()?.sdkStateListener(
                object : MoveSdk.StateListener {
                    override fun onStateChanged(sdk: MoveSdk, state: MoveSdkState) {
                        uiThreadHandler.post {
                            events?.success(state.name)
                        }
                    }
                }
            )
        }
    }

    /// Cancel listening for SDK state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Trip state handler.
class TripStateStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for trip state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
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

    /// Cancel listening for trip state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Auth state handler.
class AuthStateStreamHandler(
    private val coroutineScope: CoroutineScope,
) : EventChannel.StreamHandler {

    private val ioContext = Dispatchers.IO
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for auth state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // trigger immediately time with current state
        coroutineScope.launch {
            val authState = withContext(ioContext) {
                MoveSdk.get()?.getAuthState()?.name ?: MoveAuthState.UNKNOWN.name
            }
            events?.success(authState)
        }
        MoveSdk.get()?.authStateUpdateListener(object : MoveSdk.AuthStateUpdateListener {
            override fun onAuthStateUpdate(state: MoveAuthState) {
                uiThreadHandler.post {
                    events?.success(state.name)
                }
            }
        })
    }

    /// Cancel listening for auth state.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Service error handler.
class ServiceErrorStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for service errors.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
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

    /// Cancel listening for service errors.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Service warning handler.
class ServiceWarningStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for service warnings.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setServiceWarningListener(object : MoveSdk.MoveWarningListener {
            override fun onMoveWarning(serviceWarnings: List<MoveServiceWarning>) {
                uiThreadHandler.post {
                    events?.success(serviceWarnings.toWarningObject())
                }
            }
        })
    }

    /// Cancel listening for service warnings.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Log handler.
class LogStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for log events.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setLogListener(object : MoveSdk.MoveLogCallback {
            override fun onLogReceived(eventName: String, value: String?) {
                uiThreadHandler.post {
                    events?.success(eventName)
                }
            }
        })
    }

    /// Cancel listening for log events.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// Device discovery handler.
class DeviceDiscoveryStreamHandler : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for device discovery.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
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

    /// Cancel listening for device discovery.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

/// BLE Device scanning handler.
/// - Parameters:
///   - context: Application context.
/// - Returns: Handler of stream setup and teardown requests.
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

    /// Callback for BLE scanning.
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

    /// Handler for BLE device scanning.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
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
        if (filters.contains(MoveDeviceFilter.CONNECTED.filter)) {
            proceedWithConnectedDevices()
        }
        if (filters.contains(MoveDeviceFilter.BEACON.filter)) {
            proceedWithBleDevices()
        }
    }

    /// Stop BLE scanning.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    @SuppressLint("MissingPermission")
    override fun onCancel(arguments: Any?) {
        events = null
        proximityId = null
        manufacturerId = null
        val bluetoothManager = context.getSystemService(BluetoothManager::class.java)
        bluetoothManager.adapter.bluetoothLeScanner.stopScan(leCallback)
    }

    /// Get proximity UUID from manufacturer specific data.
    /// - Parameters:
    ///   - manufacturerSpecificData: Manufacturer specific data.
    /// - Returns: Proximity UUID.
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

    /// Proceed with paired devices.
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

    private fun proceedWithConnectedDevices() {
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
        val connectedDevices = mutableSetOf<MoveDevice>()
        bondedDevices.forEach { device ->
            if (device.isConnected) {
                if (!connectedDevices.contains(device)) {
                    connectedDevices.add(device)
                }
            }
        }
        uiThreadHandler.post {
            events?.success(connectedDevices.toList().toMoveDeviceObjectList())
        }
    }

    /// Proceed with BLE devices.
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

    /// Check if permission is granted.
    /// - Parameters:
    ///   - permission: Manifest permission name to check.
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

    /// BT Device filter.
    /// - Parameters:
    ///   - filter: Filter name.
    enum class MoveDeviceFilter(val filter: String) {
        BEACON("beacon"),
        CONNECTED("connected"),
        PAIRED("paired");
    }
}

/// Config change handler.
class ConfigChangeStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for config changes.
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

    /// Cancel listening for config changes.
    override fun onCancel(arguments: Any?) {
    }
}

/// Trip start handler.
class TripStartStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    /// Listen for trip start.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    ///   - events: an EventChannel.EventSink for emitting events to the Flutter receiver.
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

    /// Cancel listening for trip start.
    /// - Parameters:
    ///   - arguments: stream configuration arguments, possibly null.
    override fun onCancel(arguments: Any?) {
    }
}

// Move device state listener
class DeviceStateStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setDeviceStateListener(
            object : MoveSdk.MoveDeviceStateListener {
                override fun onStateChanged(device: MoveDevice) {
                    uiThreadHandler.post {
                        events?.success(
                            listOf(
                                mapOf(
                                    "name" to device.name,
                                    "data" to device.toJsonString(),
                                    "isConnected" to device.isConnected,
                                )
                            )
                        )
                    }
                }
            }
        )
    }

    override fun onCancel(arguments: Any?) {
    }
}

class HealthListenerStreamHandler() : EventChannel.StreamHandler {
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        MoveSdk.get()?.setMoveHealthScoreListener(
            object : MoveSdk.MoveHealthScoreListener {
                override fun onMoveHealthScoreChanged(result: MoveHealthScore) {
                    val reasonName: String = result.reason.firstOrNull()?.name ?: ""
                    var description =
                        "Mobile Conn.: ${result.mobileConnection}"
                    uiThreadHandler.post {
                        events?.success(
                            listOf(
                                mapOf(
                                    "reason" to reasonName,
                                    "description" to description,
                                )
                            )
                        )
                    }
                }
            }
        )
    }

    /// Cancel listening for health listener changes.
    override fun onCancel(arguments: Any?) {
    }
}
