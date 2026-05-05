/// A device filter passed in `startScanningDevices`.
enum MoveDeviceFilter {
  /// iBeacon devices, requires uuid and or manufacurer id.
  beacon,

  /// Connected bluetooth device.
  connected,

  /// Paired bluetooth device.
  paired,
}

enum MoveDeviceState {
  /// Device is not synchronized with the backend.
  notSynchronized,

  /// Device is synchronized with the backend.
  ok,
}

/// Move discoverable device
class MoveDevice {
  /// Device name sent to server.
  String name;

  /// Raw device data.
  String data;

  /// Is device paired.
  bool isConnected;

  /// Device state update after synchronization failure.
  MoveDeviceState state;

  /// Raw device data.
  String displayName;

  MoveDevice(
    this.name,
    this.data,
    this.isConnected,
    this.displayName,
    this.state,
  );

  /// Convert [devices] from native code.
  static List<MoveDevice> fromNative(devices) {
    List<MoveDevice> deviceList = [];
    for (var device in devices) {
      String name = device["name"];
      String displayName = device["displayName"] ?? "";
      String data = device["data"];
      MoveDeviceState state = MoveDeviceState.values.firstWhere(
        (e) =>
            e.name.toUpperCase() ==
            (device["state"] as String).toUpperCase().replaceAll("_", ""),
        orElse: () => MoveDeviceState.notSynchronized,
      );
      bool isString = device["isConnected"] is String;
      bool isConnected = false;
      if (isString) {
        isConnected = device["isConnected"] == "true";
      } else {
        isConnected = device["isConnected"];
      }
      deviceList.add(MoveDevice(name, data, isConnected, displayName, state));
    }
    return deviceList;
  }
}
