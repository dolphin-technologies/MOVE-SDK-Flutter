import Flutter
import DolphinMoveSDK

/// Wrapper error objects.
internal struct MoveSdkError: Error {
	/// Auth invalid error.
	static let authInvalid = FlutterError(code: "authInvalid", message: "Auth Invalid.", details: nil)
	/// Location error.
	static let locationError = FlutterError(code: "locationError", message: "Location Error.", details: nil)
	/// Network error.
	static let networkError = FlutterError(code: "networkError", message: "Network Error.", details: nil)
	/// Address resolution failure error.
	static let resolveFailed = FlutterError(code: "resolveFailed", message: "Resolve Failed.", details: nil)
	/// SDK setup error.
	static let setupError = FlutterError(code: "setupError", message: "Setup Error.", details: nil)
	/// Throttle violated.
	static let throttle = FlutterError(code: "throttle", message: "Maximum tries for method.", details: nil)
	/// Threshold violated.
	static let thresholdReached = FlutterError(code: "thresholdReached", message: "Maximum tries for method.", details: nil)
	/// Uninitialized error.
	static let uninitialized = FlutterError(code: "uninitialized", message: "SDK Uninitialized.", details: nil)
	/// Initialization failure error.
	static let initializationError = FlutterError(code: "initializationError", message: "SDK Uninitialized.", details: nil)

	/// Invalid argument error.
	/// - Parameters:
	///   - args: Missing argument key identifiers.
	///
	/// - Returns: Returns an invalid argument flutter errror object.
	static func invalidArguments(_ args: [MoveSdkArgument]) -> FlutterError { FlutterError(code: "invalidArguments", message: "Invalid Arguments.", details: "Required: \(args).")
	}
}

/// Wrapped SDK error/warning reason key strings.
internal enum MoveSdkReason: String {
	/// Motion activity permission missing.
	case activityPermissionMissing
	/// Background permission missing.
	case backgroundLocationPermissionMissing
	/// Battery optimization. Android only.
	case batteryOptimization
	/// Bluetooth permission missing.
	case bluetoothPermissionMissing
	/// Bluetooth turned off.
	///
	/// Only available if bluetooth permission given.
	case bluetoothTurnedOff
	/// Energy saver. Android only.
	case energySaver
	/// Go edition. Android only.
	case goEdition
	/// GPS off. Android only.
	case gpsOff
	/// Location mode. Android only.
	case locationMode
	/// Location power mode. Android only.
	case locationPowerMode
	/// Mock provider. Android only.
	case mockProvider
	/// Mock provider location. Android only.
	case mockProviderLocation
	/// No sim. Android only.
	///
	/// Not possible to check on iOS.
	case noSim
	/// Offline. Android only.
	case offline
	/// Play services missing. Android only.
	case playServicesMissing
	/// Rooted. Android only.
	case rooted

	/// Accelerometer missing.
	///
	/// Fault in accelerometer detected.
	case accelerometerMissing
	/// Battery permission missing. Android only.
	case batteryPermissionMissing
	/// Gyroscope missing.
	///
	/// Fault in gyroscope detected.
	case gyroscopePermissionMissing
	/// Internet permission missing. Android only.
	case internetPermissionMissing
	/// Location permission missing.
	case locationPermissionMissing
	/// Notification permission missing.
	case notificationMissing
	/// Phone permission missing. Android only.
	case phonePermissionMissing
	/// Precise location restricted by user.
	case preciseLocationPermissionMissing
	/// Overlay permission missing. Android only.
	case overlayPermissionMissing
	/// Service is disabled on Move dashboard.
	case unauthorized

	/// Translates a `MovePermission` into a permission key.
	/// - Parameters:
	///   - movePermission: `MovePermission` object from error/warning listener or `getServiceFailures()`/`getServiceWarnings()`.
	init?(_ movePermission: MovePermission) {
		switch movePermission {

		case .location:
			self = .locationPermissionMissing
		case .backgroundLocation:
			self = .backgroundLocationPermissionMissing
		case .preciseLocation:
			self = .preciseLocationPermissionMissing
		case .motionActivity:
			self = .activityPermissionMissing
		case .gyroscope:
			self = .gyroscopePermissionMissing
		case .accelerometer:
			self = .accelerometerMissing
		case .bluetooth:
			self = .bluetoothTurnedOff
		case .bluetoothScan:
			self = .bluetoothPermissionMissing
		@unknown default:
			return nil
		}
	}
}
