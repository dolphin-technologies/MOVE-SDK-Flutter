package com.movesdk

internal interface MoveSdkFlutter {
    /// Get the warnings.
    fun getWarnings()
    /// Get the errors.
    fun getErrors()
    /// Allow mock locations.
    fun allowMockLocations()
    /// No implementation.
    fun consoleLogging()
    /// No implementation.
    fun notifications()
    /// Setup the MOVE SDK.
    fun setup()
    /// Setup the MOVE SDK with authentication.
    fun setupWithCode()
    /// Update the MOVE SDK config.
    fun updateConfig()
    @Deprecated("Update auth is obsolete.")
    fun updateAuth()
    /// Start the MOVE SDK trip detection.
    fun startAutomaticDetection()
    /// Stop the MOVE SDK trip detection.
    fun stopAutomaticDetection()
    /// Trigger the MOVE SDK trip detection.
    fun forceTripRecognition()
    /// Finish a trip manually.
    fun finishCurrentTrip()
    /// Ignore the current trip.
    fun ignoreCurrentTrip()
    /// Initiate an assistance call.
    fun initiateAssistanceCall()
    /// Get the MOVE SDK state.
    fun getSdkState()
    /// Get the MOVE SDK trip state.
    fun getTripState()
    /// Get the MOVE SDK authentication state.
    fun getAuthState()
    /// Get the status of the device.
    fun getDeviceStatus()
    /// Get the MOVE SDK configuration.
    fun getMoveConfig()
    /// Delete all local data.
    fun deleteLocalData()
    /// Shutdown the MOVE SDK.
    fun shutdown()
    /// Synchronize the user data.
    fun synchronizeUserData()
    /// Fetch the user config.
    fun fetchUserConfig()
    /// Keep the MOVE SDK in the foreground.
    fun keepInForeground()
    /// Check if the MOVE SDK is kept in the foreground.
    fun isKeepInForegroundOn()
    /// Keep the MOVE SDK active.
    fun keepActive()
    /// Check if the MOVE SDK is kept active.
    fun isKeepActiveOn()
    /// Resolve an occured error.
    fun resolveError()
    /// Get the address from coordinates.
    fun geocode()
    // Use PowerManager to keep some parts alive.
    fun useWakelocks()
    /// Set the assistance metadata.
    fun setAssistanceMetaData()
    /// Get the device qualifier.
    fun getDeviceQualifier()
    /// Get the platform version.
    fun getPlatformVersion()
    /// Get the MOVE SDK version.
    fun getMoveVersion()
    /// Init the MOVE SDK.
    fun init()
    /// Register BT devices for scanning.
    fun registerDevices()
    /// Unregister BT devices for scanning.
    fun unregisterDevices()
    /// Get the registered BT devices.
    fun getRegisteredDevices()
    /// Creates the recognition notification.
    fun recognitionNotification()
    /// Creates the notifications.
    fun startTrip()
    fun setLiveLocationTag()
}