/// A device filter passed in `startScanningDevices`.
enum MoveDeviceFilter {
  /// iBeacon devices, requires uuid and or manufacurer id.
  beacon,

  /// Connected bluetooth device.
  connected,

  /// Paired bluetooth device.
  paired,
}

/// Move discoverable device
class MoveDevice {
  /// Device name sent to server.
  String name;

  /// Raw device data.
  String data;

  /// Is device paired.
  bool isConnected;

  MoveDevice(this.name, this.data, this.isConnected);

  /// Convert [devices] from native code.
  static List<MoveDevice> fromNative(devices) {
    List<MoveDevice> deviceList = [];
    for (var device in devices) {
      String name = device["name"];
      String data = device["data"];
      bool isString = device["isConnected"] is String;
      bool isConnected = false;
      if (isString) {
        isConnected = device["isConnected"] == "true";
      } else {
        isConnected = device["isConnected"];
      }

      deviceList.add(MoveDevice(name, data, isConnected));
    }
    return deviceList;
  }
}
