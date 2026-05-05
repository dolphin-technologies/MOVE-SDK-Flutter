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

  /// If set to true devices which fail synchronisation with the backend
  /// will automatically be unregistered.
  bool? ensureSynced;

  DeviceDiscoveryOptions(
      {this.startDelay,
      this.duration,
      this.interval,
      this.stopScanOnFirstDiscovered,
      this.ensureSynced});
}
