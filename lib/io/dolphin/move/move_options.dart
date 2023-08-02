import 'device_discovery_options.dart';

/// A move options struct passed in `setup`.
class MoveOptions {
  /// Allows to set Motion Permission as mandatory
  bool? motionPermissionMandatory;

  /// Configuration of the Device Discovery service
  DeviceDiscoveryOptions? deviceDiscovery;

  MoveOptions({this.motionPermissionMandatory, this.deviceDiscovery});
}
