/// A device filter passed in `startScanningDevices`.
enum MoveDeviceFilter {
  /// iBeacon devices, requires uuid and or manufacurer id.
  beacon,

  /// Paired bluetooth device.
  paired,
}

/// Move discoverable device
class MoveDevice {
  /// Device name sent to server.
  String name;

  /// Raw device data.
  String data;

  MoveDevice(this.name, this.data);

  static List<MoveDevice> fromNative(devices) {
    List<MoveDevice> deviceList = [];
    for (var device in devices) {
      String name = device["name"];
      String data = device["data"];

      deviceList.add(MoveDevice(name, data));
    }
    return deviceList;
  }
}
