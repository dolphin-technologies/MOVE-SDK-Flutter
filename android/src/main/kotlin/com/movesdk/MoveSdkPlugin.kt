package com.movesdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.dolphin.move.MoveAuthState
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




