import Flutter

internal enum MoveSdkMethod: String {
	case finishCurrentTrip
	case forceTripRecognition
	case geocode
	case getAuthState
	case getDeviceQualifier
	case getRegisteredDevices
	case getState = "getSdkState"
	case getErrors
	case getWarnings
	case getTripState
	case getPlatformVersion
	case ignoreCurrentTrip
	case initiateAssistanceCall
	case registerDevices
	case resolveError
	case setAssistanceMetaData
	case setup
	case shutdown
	case startAutomaticDetection
	case stopAutomaticDetection
	case synchronizeUserData
	case unregisterDevices
	case updateAuth
	case updateConfig
}

internal enum MoveSdkArgument: String {
	// listener
	case listener

	// config
	case config
	case options

	// auth
	case accessToken
	case projectId
	case refreshToken
	case userId

	// geocode
	case latitude
	case longitude

	// metadata
	case metadata

	// shutdown
	case force

	// scanner
	case devices
	case uuid
	case filter
	case paired
	case beacon

	func from<T>(_ arguments: Any?) -> T? {
		(arguments as? [String: Any])?[self.rawValue] as? T
	}
}

internal extension FlutterMethodCall {
	subscript<T>(argument: MoveSdkArgument) -> T? {
		(arguments as? [String: Any])?[argument.rawValue] as? T
	}
}

internal enum MoveSdkListener: String, CaseIterable {
	case auth
	case failures
	case log
	case metadata
	case state
	case trip
	case warnings
}

internal enum MoveSdkDartMethod: String {
	case onStateChange
	case onTripStateChange
	case onAuthStateChange
	case onLog
	case onWarnings
	case onFailures
}
