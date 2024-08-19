import Flutter

/// MoveSDK wrapper method identifiers.
internal enum MoveSdkMethod: String {
	/// `finishCurrentTrip()`.
	case finishCurrentTrip
	/// `forceTripRecognition()`.
	case forceTripRecognition
	/// `geocode(latitude:longitude)`.
	case geocode
	/// `getAuthState()`.
	case getAuthState
	/// `getDeviceQualifier()`.
	case getDeviceQualifier
	/// `getRegisteredDevices()`.
	case getRegisteredDevices
	/// `getSDKState()`.
	case getState = "getSdkState"
	/// `getServiceErrors()`.
	case getErrors
	/// `getServiceWarnings()`.
	case getWarnings
	/// `getTripState()`.
	case getTripState
	/// `getPlatformVersion()`.
	case getPlatformVersion
	/// `ignoreCurrentTrip()`.
	case ignoreCurrentTrip
	/// `initiateAssistanceCall()`.
	case initiateAssistanceCall
	/// `register(devices:)`.
	case registerDevices
	/// `resolveError`.
	case resolveError
	/// `setAssistanceMetaData(:)`.
	case setAssistanceMetaData
	/// `setLiveLocationTag(:)`
	case setLiveLocationTag
	/// `setup(auth:config:options:)`.
	case setup
	/// `setup(authCode:config:options:)`.
	case setupWithCode
	/// `shutdown(force:)`.
	case shutdown
	/// `startAutomaticDetection()`.
	case startAutomaticDetection
	/// `startTrip(metadata:)`.
	case startTrip
	/// `stopAutomaticDetection()`.
	case stopAutomaticDetection
	/// `synchronizeUserData()`.
	case synchronizeUserData
	/// `unregister(devices:)`.
	case unregisterDevices
	/// `update(auth:)`.
	case updateAuth
	/// `update(config:)`.
	case updateConfig
}

/// MoveSDK wrapper argument identifiers.
internal enum MoveSdkArgument: String {
	// listener
	/// Listener.
	case listener

	// config
	/// Config.
	case config
	/// Options.
	case options

	// auth
	/// Access token.
	case accessToken
	/// Project ID.
	case projectId
	/// Refresh token.
	case refreshToken
	/// User ID.
	case userId
	/// Auth code.
	case authCode

	// geocode
	/// Coordinate latitude.
	case latitude
	/// Coordinate longitude.
	case longitude

	// metadata
	/// Metadata.
	case metadata
	/// Tag.
	case tag

	// shutdown
	/// Shutdown force.
	case force

	// scanner
	/// Devices.
	case devices
	/// Proximity UUID.
	case uuid
	/// Filter.
	case filter
	/// Paired audio output devices.
	case paired
	/// iBeacon devices.
	case beacon

	/// Parse argument from arguments object.
	/// - Parameters:
	///   - arguments: Flutter method arguments dictionary.
	func from<T>(_ arguments: Any?) -> T? {
		(arguments as? [String: Any])?[self.rawValue] as? T
	}
}

internal extension FlutterMethodCall {
	/// Parse arguments from a flutter method call.
	/// - Parameters:
	///   - arguments: Flutter method arguments dictionary.
	subscript<T>(argument: MoveSdkArgument) -> T? {
		(arguments as? [String: Any])?[argument.rawValue] as? T
	}
}

/// MoveSDK wrapper listener identifiers.
internal enum MoveSdkListener: String, CaseIterable {
	/// Auth listener.
	case auth
	/// Service error listener.
	case failures
	/// Log listener.
	case log
	/// Metadata listener.
	case metadata
	/// SDK state listener.
	case state
	/// Trip listener.
	case trip
	/// Service warning listener.
	case warnings
}

/// MoveSDK wrapper callback identifiers.
internal enum MoveSdkDartMethod: String {
	/// State change callback.
	case onStateChange
	/// Trip state change callback.
	case onTripStateChange
	/// Auth state change callback.
	case onAuthStateChange
	/// Public log message callback.
	case onLog
	/// Service warnings callback.
	case onWarnings
	/// Service failures callback.
	case onFailures
}
