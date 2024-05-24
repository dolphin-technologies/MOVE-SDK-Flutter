package com.movesdk

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.gson.Gson
import io.dolphin.move.DeviceDiscovery
import io.dolphin.move.DrivingService
import io.dolphin.move.GeocodeResult
import io.dolphin.move.MoveAssistanceCallStatus
import io.dolphin.move.MoveAuth
import io.dolphin.move.MoveAuthError
import io.dolphin.move.MoveAuthState
import io.dolphin.move.MoveConfig
import io.dolphin.move.MoveDetectionService
import io.dolphin.move.MoveDevice
import io.dolphin.move.MoveGeocodeError
import io.dolphin.move.MoveNotification
import io.dolphin.move.MoveOptions
import io.dolphin.move.MoveSdk
import io.dolphin.move.MoveSdkState
import io.dolphin.move.MoveServiceFailure
import io.dolphin.move.MoveServiceWarning
import io.dolphin.move.MoveShutdownResult
import io.dolphin.move.WalkingService
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private val gson = Gson()

/// This class is responsible for handling all the method calls
/// from the Flutter side.
/// - Parameters:
///   - context: a context.
///   - call: [MethodCall].
///   - result: A [MethodChannel.Result] used for submitting the result of the call.
internal class MoveSdkFlutterAdapter(
    private val context: Context,
    private val call: MethodCall,
    private val result: MethodChannel.Result,
) : MoveSdkFlutter {
    /// This handler is used to post the result back to the main thread.
    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
    /// This scope is used to launch coroutines on the main thread.
    private val mainScope = CoroutineScope(Dispatchers.Main)
    /// This scope is used to launch coroutines on the IO thread.
    private val ioContext = Dispatchers.IO

    /// Get the warnings.
    override fun getWarnings() {
        val serviceWarnings: List<MoveServiceWarning>? = MoveSdk.get()?.getServiceWarnings()
        val errors: List<Map<String, Any>> = serviceWarnings?.toWarningObject() ?: emptyList()
        result.success(errors)
    }

    /// Get the errors.
    override fun getErrors() {
        val serviceErrors: List<MoveServiceFailure>? = MoveSdk.get()?.getServiceErrors()
        val errors: List<Map<String, Any>> = serviceErrors?.toErrorObject() ?: emptyList()
        result.success(errors)
    }

    /// Allow mock locations.
    override fun allowMockLocations() {
        val allow = call.argument<Boolean>("allow")
        MoveSdk.get()?.allowMockLocations(allow == true)
        result.success(null)
    }

    override fun consoleLogging() {
        // No implementation
    }

    override fun notifications() {
        // No implementation
    }

    /// Setup the MOVE SDK.
    override fun setup() {
        val moveAuth = extractMoveAuth(call)
        val moveConfig = extractMoveConfig(call)
        val moveOptions = extractMoveOptions(call)
        MoveSdk.setup(auth = moveAuth, moveConfig, options = moveOptions)
        result.success("setup")
    }

    /// Update the MOVE SDK config.
    override fun updateConfig() {
        val moveConfig = extractMoveConfig(call)
        MoveSdk.get()?.updateConfig(moveConfig)
    }

    @Deprecated("Update auth is obsolete.")
    override fun updateAuth() {
        val moveAuth = extractMoveAuth(call)
        MoveSdk.get()?.updateAuth(moveAuth) { configurationError: MoveAuthError ->
            uiThreadHandler.post {
                when (configurationError) {
                    is MoveAuthError.AuthInvalid -> result.error(
                        "authInvalid",
                        null,
                        null
                    )

                    is MoveAuthError.ServiceUnreachable -> result.error(
                        "serviceUnreachable",
                        null,
                        null
                    )

                    is MoveAuthError.Throttle -> result.error(
                        "throttle",
                        null,
                        null
                    )

                    else -> result.success("success")
                }
            }
            result.success("updateAuth")
        }
    }

    /// Start the MOVE SDK trip detection.
    override fun startAutomaticDetection() {
        if (MoveSdk.get()?.startAutomaticDetection() == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    /// Stop the MOVE SDK trip detection.
    override fun stopAutomaticDetection() {
        if (MoveSdk.get()?.stopAutomaticDetection() == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    /// Trigger the MOVE SDK trip detection.
    override fun forceTripRecognition() {
        MoveSdk.get()?.forceTripRecognition()
        result.success(null)
    }

    /// Finish a trip manually.
    override fun finishCurrentTrip() {
        MoveSdk.get()?.finishCurrentTrip()
        result.success(null)
    }

    /// Ignore the current trip.
    override fun ignoreCurrentTrip() {
        MoveSdk.get()?.ignoreCurrentTrip()
        result.success("ignoreCurrentTrip")
    }

    /// Initiate an assistance call.
    override fun initiateAssistanceCall() {
        MoveSdk.get()?.initiateAssistanceCall(object : MoveSdk.AssistanceStateListener {
            override fun onAssistanceStateChanged(assistanceState: MoveAssistanceCallStatus) {
                uiThreadHandler.post {
                    when (assistanceState) {
                        MoveAssistanceCallStatus.SUCCESS -> result.success("success")
                        MoveAssistanceCallStatus.INITIALIZATION_ERROR -> result.error(
                            "initializationError",
                            null,
                            null
                        )

                        MoveAssistanceCallStatus.NETWORK_ERROR -> result.error(
                            "networkError",
                            null,
                            null
                        )
                    }
                }
            }
        })
    }

    /// Get the MOVE SDK state.
    override fun getSdkState() {
        mainScope.launch {
            val sdkState = withContext(ioContext) {
                MoveSdk.get()?.getSdkState()?.name ?: MoveSdkState.Uninitialised.name
            }
            result.success(sdkState)
        }
    }

    /// Get the MOVE SDK trip state.
    override fun getTripState() {
        val tripState = MoveSdk.get()?.getTripState()?.name
        result.success(tripState)
    }

    /// Get the MOVE SDK authentication state.
    override fun getAuthState() {
        mainScope.launch {
            val authState = withContext(ioContext) {
                MoveSdk.get()?.getAuthState()?.name ?: MoveAuthState.UNKNOWN.name
            }
            result.success(authState)
        }
    }

    /// Get the status of the device.
    override fun getDeviceStatus() {
        val deviceStatus = MoveSdk.get()?.getDeviceStatus()
        val deviceStatusJson = gson.toJson(deviceStatus)
        result.success(deviceStatusJson)
    }

    /// Get the MOVE SDK configuration.
    override fun getMoveConfig() {
        result.success(MoveSdk.get()?.getMoveConfig())
    }

    /// Delete all local data.
    override fun deleteLocalData() {
        MoveSdk.get()?.deleteLocalData()
        result.success("deleteLocalData")
    }

    /// Shutdown the MOVE SDK.
    override fun shutdown() {
        val force = call.argument<Boolean>("force") == true
        MoveSdk.get()?.shutdown(force) { shutdownResult ->
            uiThreadHandler.post {
                when (shutdownResult) {
                    MoveShutdownResult.SUCCESS -> result.success("success")
                    MoveShutdownResult.UNINITIALIZED -> result.error("uninitialized", null, null)
                    MoveShutdownResult.NETWORK_ERROR -> result.error("networkError", null, null)
                }
            }
        }
    }

    /// Synchronize the user data.
    override fun synchronizeUserData() {
        MoveSdk.get()?.synchronizeUserData(object : (Boolean) -> Unit {
            override fun invoke(success: Boolean) {
                uiThreadHandler.post {
                    result.success(success)
                }
            }
        })
    }

    /// Fetch the user config.
    override fun fetchUserConfig() {
        MoveSdk.get()?.fetchUserConfig()
        result.success("fetchUserConfig")
    }

    /// Keep the MOVE SDK in the foreground.
    override fun keepInForeground() {
        val enabled = call.argument<Boolean>("enabled")
        MoveSdk.get()?.keepInForeground(enabled == true)
        result.success(null)
    }

    /// Check if the MOVE SDK is kept in the foreground.
    override fun isKeepInForegroundOn() {
        val isKeepInForegroundOn = MoveSdk.get()?.isKeepInForegroundOn() == true
        result.success(isKeepInForegroundOn)
    }

    /// Keep the MOVE SDK active.
    override fun keepActive() {
        val enabled = call.argument<Boolean>("enabled")
        MoveSdk.get()?.keepActive(enabled == true)
        result.success(null)
    }

    /// Check if the MOVE SDK is kept active.
    override fun isKeepActiveOn() {
        val isKeepActiveOn = MoveSdk.get()?.isKeepActiveOn() == true
        result.success(isKeepActiveOn)
    }

    /// Resolve an occured error.
    override fun resolveError() {
        MoveSdk.get()?.resolveError()
        result.success(null)
    }

    /// Get the address from coordinates.
    override fun geocode() {
        val latitude = call.argument<Double>("latitude") ?: 0.0
        val longitude = call.argument<Double>("longitude") ?: 0.0

        MoveSdk.get()
            ?.geocode(latitude, longitude, object : (io.dolphin.move.GeocodeResult) -> Unit {
                override fun invoke(geocodeResult: GeocodeResult) {
                    uiThreadHandler.post {
                        val error = geocodeResult.error
                        if (error == null) {
                            result.success(geocodeResult.address)
                        } else {
                            when (error) {
                                MoveGeocodeError.RESOLVE_FAILED -> result.error(
                                    "resolveFailed",
                                    null,
                                    null
                                )

                                MoveGeocodeError.SERVICE_UNREACHABLE -> result.error(
                                    "serviceUnreachable", null,
                                    null
                                )

                                MoveGeocodeError.THRESHOLD_REACHED -> result.error(
                                    "thresholdReached", null,
                                    null
                                )

                                else -> {}
                            }
                        }
                    }
                }
            })
    }

    // Use PowerManager to keep some parts alive.
    override fun useWakelocks() {
        val recognition = call.argument<Boolean>("recognition")
        val sensors = call.argument<Boolean>("sensors")
        val critical = call.argument<Boolean>("critical")
        MoveSdk.get()?.useWakelocks(
            recognition = recognition == true,
            sensors = sensors == true,
            critical = critical == true,
        )
        result.success(null)
    }

    /// Set the assistance metadata.
    override fun setAssistanceMetaData() {
        val assistanceMetadataValue = call.argument<String>("assistanceMetadataValue")
        MoveSdk.get()?.setAssistanceMetaData(assistanceMetadataValue)
        result.success(null)
    }

    /// Get the device qualifier.
    override fun getDeviceQualifier() {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }

    /// Get the platform version.
    override fun getPlatformVersion() {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
    }

    /// Get the MOVE SDK version.
    override fun getMoveVersion() {
        result.success(MoveSdk.version)
    }

    /// Init the MOVE SDK.
    override fun init() {
        MoveSdk.init(context)
        result.success("init")
    }

    /// Register BT devices for scanning.
    override fun registerDevices() {
        mainScope.launch {
            val registerResult = withContext(ioContext) {
                val devices = call.argument<Map<String, String>>("devices")?.map {
                    try {
                        gson.fromJson(it.value, MoveDevice::class.java)
                    } catch (e: Exception) {
                        null
                    }
                }?.filterNotNull().orEmpty()
                MoveSdk.get()?.registerDevices(devices)
            }
            if (registerResult == true) {
                result.success(null)
            } else {
                result.error("ERROR_REGISTER_DEVICES", null, null)
            }
        }
    }

    /// Unregister BT devices for scanning.
    override fun unregisterDevices() {
        mainScope.launch {
            val unregisterResult = withContext(ioContext) {
                val devices = call.argument<Map<String, String>>("devices")?.map {
                    try {
                        gson.fromJson(it.value, MoveDevice::class.java)
                    } catch (e: Exception) {
                        null
                    }
                }?.filterNotNull().orEmpty()
                MoveSdk.get()?.unregisterDevices(devices)
            }
            if (unregisterResult == true) {
                result.success(null)
            } else {
                result.error("ERROR_UNREGISTER_DEVICES", null, null)
            }
        }
    }

    /// Get the registered BT devices.
    override fun getRegisteredDevices() {
        mainScope.launch {
            val devices = mutableListOf<MoveDevice>()
            withContext(ioContext) {
                MoveSdk.get()?.getRegisteredDevices()?.let(devices::addAll)
            }
            result.success(devices.toMoveDeviceObjectList())
        }
    }

    /// Creates the recognition notification.
    override fun recognitionNotification() {
        val notification = createChannelGetNotification() ?: return
        MoveSdk.get()?.recognitionNotification(notification)
    }

    /// Creates the trip notification.
    override fun tripNotification() {
        val notification = createChannelGetNotification() ?: return
        MoveSdk.get()?.tripNotification(notification)
    }

    /// Creates the walking notification.
    override fun walkingLocationNotification() {
        val notification = createChannelGetNotification() ?: return
        MoveSdk.get()?.walkingLocationNotification(notification)
    }

    override fun startTrip() {
        val devices = call.argument<Map<String, String>>("metadata")
        if (MoveSdk.get()?.startTrip(devices) == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    override fun setLiveLocationTag() {
        val tag = call.argument<String>("tag")
        if (MoveSdk.get()?.setLiveLocationTag(tag) == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    /// Get the MOVE SDK config.
    /// - Parameters:
    ///   - call: [MethodCall].
    /// - Returns: [MoveConfig].
    private fun extractMoveConfig(call: MethodCall): MoveConfig {
        val services =
            call.argument<List<Any>>("config")?.map { it.toString() } ?: emptyList()

        val timelineDetectionServicesToUse = mutableListOf<MoveDetectionService>()
        val drivingServicesToUse = mutableListOf<DrivingService>()
        val walkingServicesToUse = mutableListOf<WalkingService>()

        for (service in services) {
            if (service.equals(DrivingService.DistractionFreeDriving.name, true)) {
                drivingServicesToUse.add(DrivingService.DistractionFreeDriving)
            } else if (service.equals(DrivingService.DrivingBehaviour.name, true)) {
                drivingServicesToUse.add(DrivingService.DrivingBehaviour)
            } else if (service.equals(DrivingService.DeviceDiscovery.name, true)) {
                drivingServicesToUse.add(DrivingService.DeviceDiscovery)
            } else if (service.equals("walkingLocation", true)) {
                walkingServicesToUse.add(WalkingService.Location)
            }
        }

        for (service in services) {
            if (service.equals(MoveDetectionService.Driving().name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.Driving(drivingServicesToUse))
            } else if (service.equals(MoveDetectionService.Cycling.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.Cycling)
            } else if (service.equals(MoveDetectionService.Places.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.Places)
            } else if (service.equals(MoveDetectionService.AssistanceCall.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.AssistanceCall)
            } else if (service.equals(MoveDetectionService.AutomaticImpactDetection.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.AutomaticImpactDetection)
            } else if (service.equals(MoveDetectionService.PublicTransport.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.PublicTransport)
            } else if (service.equals(MoveDetectionService.PointsOfInterest.name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.PointsOfInterest)
            } else if (service.equals(MoveDetectionService.Walking().name(), true)) {
                timelineDetectionServicesToUse.add(MoveDetectionService.Walking(walkingServicesToUse))
            }
        }
        return MoveConfig(timelineDetectionServicesToUse)
    }

    /// Get the MOVE SDK authentication
    /// - Parameters:
    ///   - call: [MethodCall].
    /// - Returns: [MoveAuth].
    private fun extractMoveAuth(call: MethodCall): MoveAuth {
        val projectId = call.argument<String>("projectId")
            ?: throw IllegalArgumentException("projectId must not be null")
        val accessToken = call.argument<String>("accessToken")
            ?: throw IllegalArgumentException("accessToken must not be null")
        val userId = call.argument<String>("userId")
            ?: throw IllegalArgumentException("userId must not be null")
        val refreshToken = call.argument<String>("refreshToken")
            ?: throw IllegalArgumentException("refreshToken must not be null")
        return MoveAuth(
            projectId = projectId.toLong(),
            userId = userId,
            accessToken = accessToken,
            refreshToken = refreshToken
        )
    }

    /// Get the MOVE SDK options.
    /// - Parameters:
    ///   - call: [MethodCall].
    /// - Returns: [MoveOptions].
    private fun extractMoveOptions(call: MethodCall): MoveOptions? {
        val options = call.argument<Map<String, Any>>("options") ?: return null
        val motionPermissionMandatory = options["motionPermissionMandatory"] as? Boolean
        val backgroundLocationPermissionMandatory =
            options["backgroundLocationPermissionMandatory"] as? Boolean
        val useBackendConfig = options["useBackendConfig"] as? Boolean
        val deviceDiscoveryOptions = (options["deviceDiscovery"] as? Map<String, Any>)?.let {
            val startDelay = (it["startDelay"] as? Int)?.toLong()
            val duration = (it["duration"] as? Int)?.toLong()
            val interval = (it["interval"] as? Int)?.toLong()
            val stopScanOnFirstDiscovered = it["stopScanOnFirstDiscovered"] as? Boolean
            DeviceDiscovery(startDelay, duration, interval, stopScanOnFirstDiscovered == true)
        }
        return MoveOptions(
            motionPermissionRequired = motionPermissionMandatory == true,
            backgroundLocationPermissionMandatory = backgroundLocationPermissionMandatory == true,
            useBackendConfig = useBackendConfig == true,
            deviceDiscovery = deviceDiscoveryOptions,
        )
    }

    /// Create a notification channel and get the notification.
    /// - Returns: [MoveNotification].
    private fun createChannelGetNotification(): MoveNotification? {
        return call.argument<Map<String, String>>("notification")?.let {
            val channelId = it["channelId"].orEmpty()
            val channelName = it["channelName"].orEmpty()
            val channelDescription = it["channelDescription"].orEmpty()
            val contentTitle = it["contentTitle"].orEmpty()
            val contentText = it["contentText"].orEmpty()
            val imageName = it["imageName"].orEmpty()
            val iconId = context.resources.getIdentifier(imageName, "drawable", context.packageName)

            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(channelId, channelName, importance)
            channel.description = channelDescription
            val notificationManager =
                context.getSystemService(Application.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            MoveNotification(
                channelId = channelId,
                drawableId = iconId,
                contentTitle = contentTitle,
                contentText = contentText,
                showWhen = true,
            )
        }
    }
}