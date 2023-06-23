import Flutter
import DolphinMoveSDK

internal struct MoveSdkError {
	static let authInvalid = FlutterError(code: "authInvalid", message: "Auth Invalid.", details: nil)
	static let locationError = FlutterError(code: "locationError", message: "Location Error.", details: nil)
	static let networkError = FlutterError(code: "networkError", message: "Network Error.", details: nil)
	static let resolveFailed = FlutterError(code: "resolveFailed", message: "Resolve Failed.", details: nil)
	static let setupError = FlutterError(code: "setupError", message: "Setup Error.", details: nil)
	static let throttle = FlutterError(code: "throttle", message: "Maximum tries for method.", details: nil)
	static let thresholdReached = FlutterError(code: "thresholdReached", message: "Maximum tries for method.", details: nil)
	static let uninitialized = FlutterError(code: "uninitialized", message: "SDK Uninitialized.", details: nil)
	static let initializationError = FlutterError(code: "initializationError", message: "SDK Uninitialized.", details: nil)

	static func invalidArguments(_ args: [MoveSdkArgument]) -> FlutterError { FlutterError(code: "invalidArguments", message: "Invalid Arguments.", details: "Required: \(args).")
	}
}

internal enum MoveSdkReason: String {
	case activityPermissionMissing
	case backgroundLocationPermissionMissing
	case batteryOptimization
	case bluetoothPermissionMissing
	case energySaver
	case goEdition
	case gpsOff
	case locationMode
	case locationPowerMode
	case mockProvider
	case mockProviderLocation
	case noSim
	case offline
	case playServicesMissing
	case rooted

	case accelerometerMissing
	case batteryPermissionMissing
	case gyroscopePermissionMissing
	case internetPermissionMissing
	case locationPermissionMissing
	case notificationMissing
	case phonePermissionMissing
	case preciseLocationPermissionMissing
	case overlayPermissionMissing
	case unauthorized

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
		@unknown default:
			return nil
		}
	}
}
