/// Device discovery options, part of `MoveOptions`.
class DeviceDiscoveryOptions {
  /// The initial delay before first scan. Default and minimal is 120 seconds.
  int? startDelay;

  /// Duration of the scan. Default is 10 seconds.
  int? duration;

  /// Interval between scans. Default is 300 seconds.
  int? interval;

  /// Allows you to stop the scan after any registered device is found.
  bool? stopScanOnFirstDiscovered;

  DeviceDiscoveryOptions({
    this.startDelay,
    this.duration,
    this.interval,
    this.stopScanOnFirstDiscovered,
  });
}
