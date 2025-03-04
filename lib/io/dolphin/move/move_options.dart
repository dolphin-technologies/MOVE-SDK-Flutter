import 'device_discovery_options.dart';

/// A move options struct passed in `setup`.
class MoveOptions {
  /// Allows to set motion permission as mandatory
  bool? motionPermissionMandatory;

  /// Allows to set background location permission as mandatory
  bool? backgroundLocationPermissionMandatory;

  /// Use all services from backend config.
  bool? useBackendConfig;

  /// Configuration of the Device Discovery service
  DeviceDiscoveryOptions? deviceDiscovery;

  MoveOptions(
      {this.motionPermissionMandatory,
      this.backgroundLocationPermissionMandatory,
      this.deviceDiscovery,
      this.useBackendConfig});

  /// Conversion to pass to native code.
  dynamic toNative() {
    return <String, dynamic>{
      'motionPermissionMandatory': motionPermissionMandatory,
      'backgroundLocationPermissionMandatory':
          backgroundLocationPermissionMandatory,
      'deviceDiscovery': <String, dynamic>{
        'startDelay': deviceDiscovery?.startDelay,
        'duration': deviceDiscovery?.duration,
        'interval': deviceDiscovery?.interval,
        'stopScanOnFirstDiscovered': deviceDiscovery?.stopScanOnFirstDiscovered,
      },
      'useBackendConfig': useBackendConfig,
    };
  }
}
