import AVFoundation
import CoreLocation
import Flutter
import Foundation
import DolphinMoveSDK

class MoveSDKDeviceScanner: NSObject {
	weak var plugin: MoveSdkPlugin?
	var sink: FlutterEventSink?

	private let allowedPorts: [AVAudioSession.Port] = [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .carAudio]

	private let session = AVAudioSession.sharedInstance()
	private let locationManager = CLLocationManager()
	private var devices: [MoveDevice] = []
	private var timer: Timer?
	private var beaconRegion: CLBeaconRegion?

	init(_ plugin: MoveSdkPlugin, registrar: FlutterPluginRegistrar) {
		let channel = FlutterEventChannel(name: "movesdk-deviceScanner", binaryMessenger: registrar.messenger())
		self.plugin = plugin
		super.init()
		channel.setStreamHandler(self)
		locationManager.delegate = self
		do {
			try session.setCategory(.playAndRecord, options: [.allowAirPlay, .allowBluetoothA2DP, .allowBluetooth])
		} catch {
			print("\(error)")
		}
	}

	func scanAudioPorts() {
		let devices: [MoveDevice] = (session.availableInputs ?? []).compactMap {
			if !allowedPorts.contains($0.portType) { return nil }
			return MoveDevice(name: "\($0.portName)[\($0.uid)]", id: $0.uid)
		}

		add(devices: devices)
	}

	func scanBeacons(uuid: UUID) {
		let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "beacons [\(uuid)]")
		locationManager.startRangingBeacons(in: beaconRegion)
		locationManager.requestState(for: beaconRegion)
		self.beaconRegion = beaconRegion
	}

	func add(devices: [MoveDevice]) {
		let devices = devices.filter { device in
			!self.devices.contains { $0 == device }
		}

		if !devices.isEmpty {
			self.devices += devices
			sink?(MoveSdkPlugin.convert(devices: devices))
		}
	}
}

extension MoveSDKDeviceScanner: FlutterStreamHandler {

	func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {

		let filter: [String] = MoveSdkArgument.filter.from(arguments) ?? []
		let filters: [MoveSdkArgument] = filter.compactMap { MoveSdkArgument(rawValue: $0) }

		sink = events

		devices = []

		if filters.contains(.paired) {
			self.scanAudioPorts()

			let timer = Timer(timeInterval: 5.0, repeats: true) { _ in
				self.scanAudioPorts()
			}

			self.timer = timer

			RunLoop.main.add(timer, forMode: .default)
		}

		if filters.contains(.beacon), let uuidString: String = MoveSdkArgument.uuid.from(arguments) {
			if let uuid = UUID(uuidString: uuidString) {
				scanBeacons(uuid: uuid)
			} else {
				return MoveSdkError.invalidArguments([.uuid])
			}
		}

		return nil
	}

	func onCancel(withArguments arguments: Any?) -> FlutterError? {
		sink = nil
		if let beaconRegion = self.beaconRegion {
			locationManager.stopRangingBeacons(in: beaconRegion)
		}
		timer?.invalidate()
		timer = nil
		return nil
	}
}

extension MoveSDKDeviceScanner: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {

		let devices = beacons.map {
			let name = "iBeacon [\($0.major):\($0.minor)]"
			return MoveDevice(name: name, proximityUUID: $0.proximityUUID, major: UInt16(truncating: $0.major), minor: UInt16(truncating: $0.minor))
		}

		add(devices: devices)
	}

	func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
		print("rangingBeaconsDidFailFor: \(region)")
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("fail: \(error)")
	}

	func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		print("monitoringDidFailFor: \(String(describing: region)) \(error)")
	}

	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		print("didEnterRegion: \(region)")
	}

	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		print("didExitRegion: \(region)")
	}

	func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
		print("didDetermineState: \(region) : \(state)")
	}
}
