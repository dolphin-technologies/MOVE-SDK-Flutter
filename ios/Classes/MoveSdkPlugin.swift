import Flutter
import UIKit
import DolphinMoveSDK

public class MoveSdkPlugin: NSObject {

	internal enum Config: String {
		case assistanceCall
		case automaticImpactDetection
		case cycling
		case driving
		case distractionFreeDriving
		case drivingBehaviour
		case deviceDiscovery
		case places
		case pointsOfInterest
		case publicTransport
		case walking
		case walkingLocation

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
			@unknown default:
				return []
			}
		}
	}

	var authStateHandler: MoveSDKStreamHandler?
	var failureHandler: MoveSDKStreamHandler?
	var logHandler: MoveSDKStreamHandler?
	var sdkStateHandler: MoveSDKStreamHandler?
	var tripStartHandler: MoveSDKStreamHandler?
	var tripStateHandler: MoveSDKStreamHandler?
	var warningHandler: MoveSDKStreamHandler?
	var deviceDiscoveryHandler: MoveSDKStreamHandler?
	var configUpdateListener: MoveSDKStreamHandler?

	var deviceSannerHandler: MoveSDKDeviceScanner?

	let sdk: MoveSDK = MoveSDK.shared

	var channel: FlutterMethodChannel? = nil

	private func callDart(method: MoveSdkDartMethod, _ arguments: Any?...) {
		DispatchQueue.main.async {
			self.channel?.invokeMethod(method.rawValue, arguments: arguments)
		}
	}

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

	static internal func convert(config: MoveConfig) -> [String] {
		var services: [String] = []
		for service in config.services {
			services += Config.convert(service: service, base: true).map { $0.rawValue }
		}
		return services
	}

	static internal func convert(devices: [MoveDevice]) -> [[String: Any]] {
		var deviceList: [[String: Any]] = []
		for device in devices {
			let encoder = JSONEncoder()
			do {
				let data = try encoder.encode(device)
				let str = String(data: data, encoding: .utf8) ?? ""
				let info: [String: Any] = ["name":device.name, "data": str]
				deviceList.append(info)
			} catch {
				print(error.localizedDescription)
			}
		}

		return deviceList
	}

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

	private func forceTripRecognition(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.forceTripRecognition()
		result(nil)
	}

	private func finishCurrentTrip(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.finishCurrentTrip()
		result(nil)
	}

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

	private func getAuthState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getAuthState()
		result("\(state)")
	}

	private func getDeviceQualifier(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let qualifier = sdk.getDeviceQualifier()
		result("\(qualifier)")
	}

	private func getPlatformVersion(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		result("iOS " + UIDevice.current.systemVersion)
	}

	private func getServiceErrors(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let errors = sdk.getServiceFailures()
		result(convert(errors: errors))
	}

	private func getServiceWarnings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let warnings = sdk.getServiceWarnings()
		result(convert(warnings: warnings))
	}

	private func getRegisteredDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let devices = sdk.getRegisteredDevices()
		result(MoveSdkPlugin.convert(devices: devices))
	}

	private func getState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getSDKState()
		result("\(state)")
	}

	private func getTripState(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let state = sdk.getTripState()
		result("\(state)")
	}

	private func ignoreCurrentTrip(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.ignoreCurrentTrip()
		result(nil)
	}

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

	private func registerDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let (devices, arguments) = getDevices(call)

		if !devices.isEmpty {
			sdk.register(devices: devices)
			result(nil)
		}

		return result(MoveSdkError.invalidArguments(arguments))
	}

	private func resolveError(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.resolveSDKStateError()
		result(nil)
	}

	private func setAssistanceMetaData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard let metadata: String = call[.metadata] else {
			result(MoveSdkError.invalidArguments([.metadata]))
			return
		}

		sdk.setAssistanceMetaData(metadata)
	}

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

		let moveOptions = MoveOptions()
		if let options: [String: Any] = call[.options] {
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
		}

		let auth = MoveAuth(userToken: accessToken, refreshToken: refreshToken, userID: userId, projectID: projectId)

		let moveConfig = convert(config: config)

		sdk.setup(auth: auth, config: moveConfig, options: moveOptions)
	}

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

	private func startAutomaticDetection(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.startAutomaticDetection()
		result(nil)
	}

	private func stopAutomaticDetection(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.stopAutomaticDetection()
		result(nil)
	}

	private func synchronizeUserData(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		sdk.synchronizeUserData { success in
			result(success)
		}
	}

	private func unregisterDevices(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		let (devices, arguments) = getDevices(call)

		if !devices.isEmpty {
			sdk.unregister(devices: devices)
			result(nil)
		}

		return result(MoveSdkError.invalidArguments(arguments))
	}

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

	private func updateConfig(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
		guard
			let config: [String] = call[.config]
		else {
			result(MoveSdkError.invalidArguments([.config]))
			return
		}

		let moveConfig = convert(config: config)
		sdk.update(config: moveConfig)
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

		instance.configUpdateListener = MoveSDKStreamHandler(instance, channel: .configChange, registrar: registrar) { sink in }

		// Device Scanning
		instance.deviceSannerHandler = MoveSDKDeviceScanner(instance, registrar: registrar)
	}

	public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
		let launchOptions = launchOptions as? [UIApplication.LaunchOptionsKey: Any]

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

		sdk.setRemoteConfigChangeListener { result in
			let data = MoveSdkPlugin.convert(config: result)
			self.configUpdateListener?.sink?(data)
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
		case .getWarnings: getServiceWarnings(call, result)
		case .getRegisteredDevices: getRegisteredDevices(call, result)
		case .getState: getState(call, result)
		case .getTripState: getTripState(call, result)
		case .ignoreCurrentTrip: ignoreCurrentTrip(call, result)
		case .initiateAssistanceCall: initiateAssistanceCall(call, result)
		case .registerDevices: registerDevices(call, result)
		case .resolveError: resolveError(call, result)
		case .setAssistanceMetaData: setAssistanceMetaData(call, result)
		case .setup: setup(call, result)
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

class MoveSDKStreamHandler: NSObject, FlutterStreamHandler {
	enum Identifier: String {
		case prefix = "movesdk-"
		case log
		case sdkState
		case tripStart
		case tripState
		case authState
		case serviceError
		case serviceWarning
		case deviceDiscovery
		case configChange
	}

	weak var plugin: MoveSdkPlugin?
	var sink: FlutterEventSink?
	var onSink: (FlutterEventSink)-> Void

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
