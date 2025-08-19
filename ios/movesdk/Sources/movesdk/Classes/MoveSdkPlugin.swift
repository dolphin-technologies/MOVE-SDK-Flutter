import Flutter
import HealthKit
import UIKit
import DolphinMoveSDK

/// MoveSDK Flutter native plugin.
///
/// Responsible for setting up the plugin.
///
/// The SDK is initialized automatically in `application(_:, didFinishLaunchingWithOptions:)`, and sets up the SDK listener handlers.
///
public class MoveSdkPlugin: NSObject {

	/// Move configuration keys.
	internal enum Config: String {
		/// Assistance call service.
		case assistanceCall
		/// Impact detection service.
		case automaticImpactDetection
		/// Cycling detection service.
		case cycling
		/// Driving detection service.
		case driving
		/// Distraction free driving subservice.
		case distractionFreeDriving
		/// Driving behavior subservice.
		case drivingBehaviour
		/// Driving device detection subservice.
		case deviceDiscovery
		/// User health service.
		case health
		/// Places service.
		case places
		/// Geofencing service.
		case pointsOfInterest
		/// Public transport service.
		case publicTransport
		/// Walking timeline service.
		case walking
		/// Walking location service.
		case walkingLocation

		/// Convert a `MoveConfig` service to a list of configuration keys.
		/// - Parameters:
		///   - service: The service to convert.
		///
		/// - Returns: Returns a list of one or more keys representing the service and subservices.
		static func convert(service: MoveConfig.DetectionService, base: Bool = false) -> [Config] {
			switch service {
			case let .driving(services):
				var config: [Config] = []
				if services.contains(.distractionFreeDriving) {
					config.append(.distractionFreeDriving)
				}
				if services.contains(.drivingBehavior) {
					config.append(.drivingBehaviour)
				}
				if services.contains(.deviceDiscovery) {
					config.append(.deviceDiscovery)
				}
				if services.isEmpty || base {
					config.append(.driving)
				}
				return config
			case .cycling:
				return [.cycling]
			case let .walking(services):
				var config: [Config] = []
				if services.contains(.location) {
					config.append(.walkingLocation)
				}
				if services.isEmpty || base {
					config.append(.walking)
				}
				return config
			case .places:
				return [.places]
			case .publicTransport:
				return [.publicTransport]
			case .pointsOfInterest:
				return [.pointsOfInterest]
			case .automaticImpactDetection:
				return [.automaticImpactDetection]
			case .assistanceCall:
				return [.assistanceCall]
			case .health:
				return [.health]
			@unknown default:
				return []
			}
		}
	}

	/// Authentication state handler.
	var authStateHandler: MoveSDKStreamHandler?

	/// Service failure handler.
	var failureHandler: MoveSDKStreamHandler?

	/// Logging handler.
	var logHandler: MoveSDKStreamHandler?

	/// SDK state handler.
	var sdkStateHandler: MoveSDKStreamHandler?

	/// Trip start handler.
	var tripStartHandler: MoveSDKStreamHandler?

	/// Trip state handler.
	var tripStateHandler: MoveSDKStreamHandler?

	/// Service warnings handler.
	var warningHandler: MoveSDKStreamHandler?

	/// Device discovery handler.
	var deviceDiscoveryHandler: MoveSDKStreamHandler?

	/// Device state updated.
	var deviceStateHandler: MoveSDKStreamHandler?

	/// Configuration update handler.
	var configUpdateListener: MoveSDKStreamHandler?

	/// SDK health handler.
	var healthListener: MoveSDKStreamHandler?

	/// Device scanner handler.
	///
	/// Device scanning needs to be triggered manually.
	var deviceSannerHandler: MoveSDKDeviceScanner?

	/// Retained `MoveSDK` singleton.
	let sdk: MoveSDK = MoveSDK.shared

	/// Flutter method channel.
	var channel: FlutterMethodChannel? = nil

	/// Current SDK health.
	var health: [MoveHealthItem] = []

	/// Current SDK configuration.
	var config: MoveConfig? = nil

	/// Healthstore to get permissions from.
	lazy var healthStore = HKHealthStore()

	/// Invoke a dart method block.
	/// - Parameters:
	///   - method: The method to call given a predefined identifier.
	///   - arguments: A flutter arguments object.
	private func callDart(method: MoveSdkDartMethod, _ arguments: Any?...) {
		DispatchQueue.main.async {
			self.channel?.invokeMethod(method.rawValue, arguments: arguments)
		}
	}

	/// Extract setup options from dictionary
	/// - Parameter options: Options dictionary.
	/// - Returns: `MoveOptions` object.
	private func convert(options: [String: Any]?) -> MoveOptions {
		let moveOptions = MoveOptions()

		guard let options else {
			return moveOptions
		}

		if let value = options["motionPermissionMandatory"] as? Bool {
			moveOptions.motionPermissionMandatory = value
		}

		if let value = options["backgroundLocationPermissionMandatory"] as? Bool {
			moveOptions.backgroundLocationPermissionMandatory = value
		}

		if let value = options["useBackendConfig"] as? Bool {
			moveOptions.useBackendConfig = value
		}

		if let deviceDiscovery = options["deviceDiscovery"] as? [String: Any] {

			if let value = deviceDiscovery["stopScanOnFirstDiscovered"] as? Bool {
				moveOptions.deviceDiscovery.stopScanOnFirstDiscovered = value
			}

			if let value = deviceDiscovery["interval"] as? Int {
				moveOptions.deviceDiscovery.interval = Double(value)
			}

			if let value = deviceDiscovery["duration"] as? Int {
				moveOptions.deviceDiscovery.duration = Double(value)
			}

			if let value = deviceDiscovery["startDelay"] as? Int {
				moveOptions.deviceDiscovery.startDelay = Double(value)
			}
		}

		return moveOptions
	}

	/// Convert a list of config strings to a `MoveConfig` object.
	/// - Parameters:
	///   - config: A list of config services.
	///
	/// - Returns: Creates a `MoveConfig` object.
	///
	/// See `setup`.
	fileprivate func convert(config: [String]) -> MoveConfig {
		let moveConfig = config.compactMap { Config(rawValue: $0) }

		var detectionServices: [MoveConfig.DetectionService] = []

		for config in moveConfig {
			switch config {
			case .assistanceCall:
				detectionServices.append(.assistanceCall)
			case .automaticImpactDetection:
				detectionServices.append(.automaticImpactDetection)
			case .cycling:
				detectionServices.append(.cycling)
			case .driving:
				var drivingServices: [MoveConfig.DrivingService] = []

				if moveConfig.contains(.distractionFreeDriving) {
					drivingServices.append(.distractionFreeDriving)
				}

				if moveConfig.contains(.drivingBehaviour) {
					drivingServices.append(.drivingBehavior)
				}

				if moveConfig.contains(.deviceDiscovery) {
					drivingServices.append(.deviceDiscovery)
				}

				detectionServices.append(.driving(drivingServices))
			case .distractionFreeDriving, .drivingBehaviour, .deviceDiscovery:
				break
			case .health:
				detectionServices.append(.health)
			case .places:
				detectionServices.append(.places)
			case .pointsOfInterest:
				detectionServices.append(.pointsOfInterest)
			case .publicTransport:
				detectionServices.append(.publicTransport)
			case .walking:
				var walkingServices: [MoveConfig.WalkingService] = []

				if moveConfig.contains(.walkingLocation) {
					walkingServices.append(.location)
				}

				detectionServices.append(.walking(walkingServices))
			case .walkingLocation:
				break
			}
		}

		return MoveConfig(detectionService: detectionServices)
	}

	/// Convert device scan results to flutter argument dictionaries.
	/// - Parameters:
	///   - scanResults: A list of device scan results.
	///
	/// - Returns: Returns a list of flutter argument dictionaries.
	///
	/// See `deviceDiscoveryHandler`.
	static internal func convert(scanResults: [MoveScanResult]) -> [[String: Any]] {
		var deviceList: [[String: Any]] = []
		for result in scanResults {
			let encoder = JSONEncoder()
			do {
				let data = try encoder.encode(result.device)
				let str = String(data: data, encoding: .utf8) ?? ""
				let info: [String: Any] = ["name": result.device.name, "device": str, "isDiscovered": result.isDiscovered]
				deviceList.append(info)
			} catch {
				print(error.localizedDescription)
			}
		}

		return deviceList
	}

	/// Convert a `MoveConfig` to a list of flutter argument strings.
	/// - Parameters:
	///   - config: The `MoveConfig` to convert.
	///
	/// - Returns: Returns a list of strings passed to a flutter method or callback.
	///
	/// See `configUpdateListener`.
	static internal func convert(config: MoveConfig) -> [String] {
		var services: [String] = []
		for service in config.services {
			services += Config.convert(service: service, base: true).map { $0.rawValue }
		}
		return services
	}
	
	/// Convert a `[MoveHealthItem]` to a list of flutter argument strings.
	/// - Parameter health: Health returned from listener.
	/// - Returns: A list of dictionaries for health reason/description.
	static internal func convert(health: [MoveHealthItem]) -> [[String: String]] {
		health.map { ["reason": $0.reason.rawValue, "description": $0.description] }
	}

	/// Convert device objects to flutter argument dictionaries.
	/// - Parameters:
	///   - devices: A list of `MoveDevice` objects.
	///
	/// - Returns: Returns a list of flutter argument dictionaries.
	///
	/// Used for `deviceDetection` service scanning.
	/// Objects are serializable back and forth between flutter and swift.
	///
	/// See `getRegisteredDevices`.
	static internal func convert(devices: [MoveDevice]) -> [[String: Any]] {
		var deviceList: [[String: Any]] = []
		for device in devices {
			let encoder = JSONEncoder()
			do {
				let data = try encoder.encode(device)
				let str = String(data: data, encoding: .utf8) ?? ""
				let info: [String: Any] = ["name": device.name, "data": str, "isConnected": device.isConnected]
				deviceList.append(info)
			} catch {
				print(error.localizedDescription)
			}
		}

		return deviceList
	}

	/// Convert errors to flutter argument dictionaries.
	/// - Parameters:
	///   - errors: A list of `MoveServiceFailure` objects.
	///
	/// - Returns: Returns a list of flutter argument dictionaries.
	///
	/// See `getServiceErrors` and `failureHandler`.
	fileprivate func convert(errors: [MoveServiceFailure]) -> [[String: Any]] {
		var errorList: [[String: Any]] = []

		for error in errors {
			var reasons: [MoveSdkReason] = []
			switch error.reason {
			case let .missingPermission(permissions):
				reasons += permissions.compactMap { MoveSdkReason($0) }
			case .unauthorized:
				reasons.append(.unauthorized)
			}

			for detectionService in Config.convert(service: error.service) {
				let service: [String: Any] = [
					"service": detectionService.rawValue,
					"reasons": reasons.map { $0.rawValue }]
				errorList.append(service)
			}
		}

		return errorList
	}

	/// Convert warnings to flutter argument dictionaries.
	/// - Parameters:
	///   - warnings: A list of `MoveServiceWarning` objects.
	///
	/// - Returns: Returns a list of flutter argument dictionaries.
	///
	/// See `getServiceWarnings` and `warningHandler`.
	fileprivate func convert(warnings: [MoveServiceWarning]) -> [[String: Any]] {
		var warningList: [[String: Any]] = []
		for warning in warnings {
			var reasons: [MoveSdkReason] = []
			switch warning.reason {
			case let .missingPermission(permissions):
				reasons += permissions.compactMap { MoveSdkReason($0) }
			}

			for detectionService in Config.convert(service: warning.service) {
				let service: [String: Any] = [
					"service": detectionService.rawValue,
					"reasons": reasons.map { $0.rawValue }]
				warningList.append(service)
			}
		}

		return warningList
	}

	/// Parse device objects from a `FlutterMethodCall`.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///
	/// - Returns: Returns a list of `MoveDevice` or a parser error identifier.
	private func getDevices(_ call: FlutterMethodCall) -> ([MoveDevice], [MoveSdkArgument])  {
		guard
			let deviceMap: [String: String] = call[.devices]
		else {
			return ([], [.devices])
		}

		do {
			let devices: [MoveDevice] = try deviceMap.map { (name, encoded) in
				let decoder = JSONDecoder()
				guard let data = encoded.data(using: .utf8) else {
					throw MoveSdkError()
				}
				let device = try decoder.decode(MoveDevice.self, from: data)
				/* overwrite device name */
				device.name = name
				return device
			}
			return (devices, [])
		} catch {
			return ([], [.devices])
		}

	}

	// MARK: Implementation

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func forceTripRecognition(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.forceTripRecognition()
		result(nil)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func finishCurrentTrip(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.finishCurrentTrip()
		result(nil)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func geocode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let latitude: Double = call[.latitude],
			let longitude: Double = call[.longitude]
		else {
			result(MoveSdkError.invalidArguments([.latitude, .longitude]))
			return
		}

		sdk.geocode(latitude: latitude, longitude: longitude) { success in
			DispatchQueue.main.async {
				switch success {
				case let .success(value):
					result(value)
				case let .failure(error):
					switch error {
					case .resolveFailed:
						result(MoveSdkError.resolveFailed)
					case .thresholdReached:
						result(MoveSdkError.thresholdReached)
					case .serviceUnreachable:
						result(MoveSdkError.networkError)
					}
				}
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getAuthState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getAuthState()
		result("\(state)")
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getDeviceQualifier(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let qualifier = sdk.getDeviceQualifier()
		result("\(qualifier)")
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getMoveVersion(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let bundle = Bundle(for: MoveSDK.self)
		if let version = bundle.infoDictionary?["CFBundleShortVersionString"],
		   let build = bundle.infoDictionary?["CFBundleVersion"] as? String {
			result("\(version).\(build)")
		} else {
			result("unknown")
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getPlatformVersion(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		result("iOS " + UIDevice.current.systemVersion)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getServiceErrors(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let errors = sdk.getServiceFailures()
		result(convert(errors: errors))
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getServiceWarnings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let warnings = sdk.getServiceWarnings()
		result(convert(warnings: warnings))
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getRegisteredDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let devices = sdk.getRegisteredDevices()
		result(MoveSdkPlugin.convert(devices: devices))
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getSDKState()
		result("\(state)")
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func getTripState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getTripState()
		result("\(state)")
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func ignoreCurrentTrip(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.ignoreCurrentTrip()
		result(nil)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func initiateAssistanceCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.initiateAssistanceCall { error in
			DispatchQueue.main.async {
				switch error {
				case .success:
					result(nil)
				case .initializationError:
					result(MoveSdkError.initializationError)
				case .networkError:
					result(MoveSdkError.networkError)
				}
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func registerDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let (devices, arguments) = getDevices(call)

		if !devices.isEmpty {
			sdk.register(devices: devices)
			result(nil)
		}

		return result(MoveSdkError.invalidArguments(arguments))
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func resolveError(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.resolveSDKStateError()
		result(nil)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func requestHealthPermissions(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let stepCountSampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!

		healthStore.requestAuthorization(toShare: [], read:  [stepCountSampleType]) { (success, error) in
			if let error {
				result(MoveSdkError.otherError(error.localizedDescription))
			} else if success {
				result(true)
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func setLiveLocationTag(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let tag: String? = call[.tag]
		let success = sdk.setLiveLocationTag(tag)
		result(success)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func setAssistanceMetaData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard let metadata: String = call[.metadata] else {
			result(MoveSdkError.invalidArguments([.metadata]))
			return
		}

		sdk.setAssistanceMetaData(metadata)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func setup(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let refreshToken: String = call[.refreshToken],
			let userId: String = call[.userId],
			let accessToken: String = call[.accessToken],
			let projectIdStr: String = call[.projectId],
			let projectId = Int64(projectIdStr),
			let config: [String] = call[.config]
		else {
			result(MoveSdkError.invalidArguments([.refreshToken, .userId, .accessToken, .projectId]))
			return
		}

		let options: [String: Any]? = call[.options]
		let moveOptions = convert(options: options)

		let auth = MoveAuth(userToken: accessToken, refreshToken: refreshToken, userID: userId, projectID: projectId)

		let moveConfig = convert(config: config)

		sdk.setup(auth: auth, config: moveConfig, options: moveOptions)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func setupWithCode(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let authCode: String = call[.authCode],
			let config: [String] = call[.config]
		else {
			result(MoveSdkError.invalidArguments([.refreshToken, .userId, .accessToken, .projectId]))
			return
		}

		let options: [String: Any]? = call[.options]
		let moveOptions = convert(options: options)
		let moveConfig = convert(config: config)

		sdk.setup(authCode: authCode, config: moveConfig, options: moveOptions) { success in
			switch success {
			case .success:
				result(true)
			case .networkError:
				result(MoveSdkError.networkError)
			case let .invalidCode(msg):
				result(MoveSdkError.invalidCode(msg))
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func shutdown(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let force: Bool = call[.force] ?? true
		sdk.shutDown(force: force) { error in
			switch error {
			case .success:
				result(nil)
			case .networkError:
				result(MoveSdkError.networkError)
			case .uninitialized:
				result(MoveSdkError.uninitialized)
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func startAutomaticDetection(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let success = sdk.startAutomaticDetection()
		result(success)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func startTrip(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let metadata: [String: String] = call[.metadata] ?? [:]
		let success = sdk.startTrip(metadata: metadata)
		result(success)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func stopAutomaticDetection(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let success = sdk.stopAutomaticDetection()
		result(success)
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func synchronizeUserData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.synchronizeUserData { success in
			result(success)
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func unregisterDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let (devices, arguments) = getDevices(call)

		if !devices.isEmpty {
			sdk.unregister(devices: devices)
			result(nil)
		}

		return result(MoveSdkError.invalidArguments(arguments))
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	@available(*, deprecated, message: "Update auth is obsolete.")
	private func updateAuth(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let refreshToken: String = call[.refreshToken],
			let userId: String = call[.userId],
			let accessToken: String = call[.accessToken],
			let projectIdStr: String = call[.projectId],
			let projectId = Int64(projectIdStr)
		else {
			result(MoveSdkError.invalidArguments([.refreshToken, .userId, .accessToken, .projectId]))
			return
		}

		let auth = MoveAuth(userToken: accessToken, refreshToken: refreshToken, userID: userId, projectID: projectId)

		sdk.update(auth: auth) { error in
			guard let error = error else {
				result(nil)
				return
			}
			switch error {
			case .authInvalid:
				result(MoveSdkError.authInvalid)
			case .throttle:
				result(MoveSdkError.throttle)
			case .serviceUnreachable:
				result(MoveSdkError.networkError)
			}
		}
	}

	/// Wrapper for SDK Method.
	/// - Parameters:
	///   - call: The `FlutterMethodCall` to parse arguments from.
	///   - result: A Flutter result callback.
	private func updateConfig(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let config: [String] = call[.config]
		else {
			result(MoveSdkError.invalidArguments([.config]))
			return
		}

		let moveConfig = convert(config: config)

		if let options: [String: Any]? = call[.options] {
			let moveOptions = convert(options: options)
			sdk.update(config: moveConfig, options: moveOptions)
		} else {
			sdk.update(config: moveConfig)
		}
		result(nil)
	}

}

extension MoveSdkPlugin: FlutterPlugin {

	public static func register(with registrar: FlutterPluginRegistrar) {
		let channel = FlutterMethodChannel(name: "movesdk", binaryMessenger: registrar.messenger())
		let instance = MoveSdkPlugin()
		registrar.addApplicationDelegate(instance)
		registrar.addMethodCallDelegate(instance, channel: channel)
		instance.channel = channel

		instance.sdkStateHandler = MoveSDKStreamHandler(instance, channel: .sdkState, registrar: registrar) { sink in
			sink("\(instance.sdk.getSDKState())")
		}

		instance.authStateHandler = MoveSDKStreamHandler(instance, channel: .authState, registrar: registrar) { sink in
			sink("\(instance.sdk.getAuthState())")
		}

		instance.tripStateHandler = MoveSDKStreamHandler(instance, channel: .tripState, registrar: registrar) { sink in
			sink("\(instance.sdk.getTripState())")
		}

		instance.tripStartHandler = MoveSDKStreamHandler(instance, channel: .tripStart, registrar: registrar) { sink in }

		instance.failureHandler = MoveSDKStreamHandler(instance, channel: .serviceError, registrar: registrar) { sink in
			sink(instance.convert(errors: instance.sdk.getServiceFailures()))
		}

		instance.logHandler = MoveSDKStreamHandler(instance, channel: .log, registrar: registrar) { _ in }

		instance.warningHandler = MoveSDKStreamHandler(instance, channel: .serviceWarning, registrar: registrar) { sink in
			sink(instance.convert(warnings: instance.sdk.getServiceWarnings()))
		}

		instance.deviceDiscoveryHandler = MoveSDKStreamHandler(instance, channel: .deviceDiscovery, registrar: registrar) { sink in }

		instance.deviceStateHandler = MoveSDKStreamHandler(instance, channel: .deviceState, registrar: registrar) { sink in }

		instance.configUpdateListener = MoveSDKStreamHandler(instance, channel: .configChange, registrar: registrar) { sink in
			if let config = instance.config {
				sink(MoveSdkPlugin.convert(config: config))
			}
		}

		instance.healthListener = MoveSDKStreamHandler(instance, channel: .sdkHealth, registrar: registrar) { sink in
			sink(MoveSdkPlugin.convert(health: instance.health))
		}

		// Device Scanning
		instance.deviceSannerHandler = MoveSDKDeviceScanner(instance, registrar: registrar)
	}

	public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
		let launchOptions = launchOptions as? [UIApplication.LaunchOptionsKey: Any]

		sdk.setHealthScoreListener { result in
			let data = MoveSdkPlugin.convert(health: result)
			self.healthListener?.sink?(data)
			self.health = result
		}

		sdk.setSDKStateListener { state in
			self.callDart(method: .onStateChange, state.rawValue)
			self.sdkStateHandler?.sink?("\(state)")
		}

		sdk.setAuthStateUpdateListener { state in
			self.callDart(method: .onAuthStateChange, state.description)
			self.authStateHandler?.sink?("\(state)")
		}

		sdk.setTripMetaDataListener { tripStart, tripEnd in
			// TODO: how to do this?
//			let result = self.sdkMetaDataSink?(["tripStart": tripStart, "tripEnd": tripEnd])
//			return result as? [String: String] ?? [:]
			return [:]
		}

		sdk.setTripStateListener { state in
			self.callDart(method: .onTripStateChange, "\(state)")
			self.tripStateHandler?.sink?("\(state)")
		}

		sdk.setTripStartListener { startDate in
			self.tripStartHandler?.sink?(Int64(startDate.timeIntervalSince1970 * 1000.0))
		}

		sdk.setServiceWarningListener { warnings in
			self.warningHandler?.sink?(self.convert(warnings: warnings))
		}

		sdk.setServiceFailureListener { failures in
			self.failureHandler?.sink?(self.convert(errors: failures))
		}

		sdk.setLogListener { event, value in
			self.callDart(method: .onLog, event, value)
			self.logHandler?.sink?([event, value])
		}

		sdk.setDeviceDiscoveryListener { results in
			let data = MoveSdkPlugin.convert(scanResults: results)
			self.deviceDiscoveryHandler?.sink?(data)
		}

		sdk.setDeviceStateListener { results in
			let data = MoveSdkPlugin.convert(devices: results)
			self.deviceStateHandler?.sink?(data)
		}

		sdk.setRemoteConfigChangeListener { result in
			let data = MoveSdkPlugin.convert(config: result)
			self.configUpdateListener?.sink?(data)
			self.config = result
		}

		sdk.initialize(launchOptions: launchOptions)
		return true
	}

	public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		guard let method = MoveSdkMethod(rawValue: call.method) else {
			result(FlutterMethodNotImplemented)
			return
		}

		switch method {
		case .finishCurrentTrip: finishCurrentTrip(call, result)
		case .forceTripRecognition: forceTripRecognition(call, result)
		case .geocode: geocode(call, result)
		case .getPlatformVersion: getPlatformVersion(call, result)
		case .getAuthState: getAuthState(call, result)
		case .getDeviceQualifier: getDeviceQualifier(call, result)
		case .getErrors: getServiceErrors(call, result)
		case .getMoveVersion: getMoveVersion(call, result)
		case .getRegisteredDevices: getRegisteredDevices(call, result)
		case .getState: getState(call, result)
		case .getWarnings: getServiceWarnings(call, result)
		case .getTripState: getTripState(call, result)
		case .ignoreCurrentTrip: ignoreCurrentTrip(call, result)
		case .initiateAssistanceCall: initiateAssistanceCall(call, result)
		case .registerDevices: registerDevices(call, result)
		case .resolveError: resolveError(call, result)
		case .requestHealthPermissions: requestHealthPermissions(call, result)
		case .setAssistanceMetaData: setAssistanceMetaData(call, result)
		case .setLiveLocationTag: setLiveLocationTag(call, result)
		case .setup: setup(call, result)
		case .setupWithCode: setupWithCode(call, result)
		case .startTrip: startTrip(call, result)
		case .startAutomaticDetection: startAutomaticDetection(call, result)
		case .stopAutomaticDetection: stopAutomaticDetection(call, result)
		case .shutdown: shutdown(call, result)
		case .synchronizeUserData: synchronizeUserData(call, result)
		case .unregisterDevices: unregisterDevices(call, result)
		case .updateAuth: updateAuth(call, result)
		case .updateConfig: updateConfig(call, result)
		}
	}
}

/// Move SDK Flutter channel handler.
///
/// Handles registration of an individual method channel handler.
class MoveSDKStreamHandler: NSObject, FlutterStreamHandler {
	/// Flutter stream channel identifier.
	enum Identifier: String {
		/// Channel prefix.
		///
		/// For all channels.
		case prefix = "movesdk-"
		/// Logging channel.
		case log
		/// SDK State channel.
		case sdkState
		/// Trip start channel.
		case tripStart
		/// Trip state channel.
		case tripState
		/// Auth state channel.
		case authState
		/// Service error channel.
		case serviceError
		/// Service warning channel.
		case serviceWarning
		/// Device discovery channel.
		case deviceDiscovery
		/// Device state channel.
		case deviceState
		/// Configuration change channel.
		case configChange
		/// SDK Health channel.
		case sdkHealth
	}

	/// A reference to the MoveSDK flutter plugin.
	weak var plugin: MoveSdkPlugin?

	/// Flutter sink where to sink channel updates to.
	var sink: FlutterEventSink?

	/// Callback when a channel is registered for.
	var onSink: (FlutterEventSink)-> Void

	/// Initialize the stream handler.
	/// - Parameters:
	///   - plugin: The MoveSDK Flutter plugin.
	///   - channel: The channel to register the handler for.
	///   - registrar: Flutter plugin registrar.
	///   - onSink: Method to call on with `FlutterEventSink` translating method arguments.
	init(_ plugin: MoveSdkPlugin, channel: Identifier, registrar: FlutterPluginRegistrar, onSink: @escaping(FlutterEventSink)-> Void) {
		let channel = FlutterEventChannel(name: Identifier.prefix.rawValue + channel.rawValue, binaryMessenger: registrar.messenger())
		self.plugin = plugin
		self.onSink = onSink
		super.init()
		channel.setStreamHandler(self)
	}

	func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
		sink = events
		onSink(events)
		return nil
	}

	func onCancel(withArguments arguments: Any?) -> FlutterError? {
		sink = nil
		return nil
	}
}
