/// Move detection services are passed to `setup(...)` / `updateConfig(...)`
enum MoveDetectionService {
  /// Enables `initiateAssistanceCall()` functionality.
  assistanceCall,

  /// Enables the automatic impact detection service, it will activate during a
  /// trip or if no trip detection is configured it will be constantly active.
  automaticImpactDetection,

  /// Cycling trip detection. Activates at lower speeds.
  cycling,

  /// Driving detection for vehicle trips.
  driving,

  /// Distraction detection based on sensors requires [driving].
  distractionFreeDriving,

  /// Driving behavior detection based on sensors requires [driving].
  drivingBehaviour,

  /// Bluetooth Device Detection based on bluetooth scanning requires [driving].
  deviceDiscovery,

  /// User health service, i.e: 'steps',
  health,

  /// Places service, (pending documentation).
  places,

  /// Points of interest service for user notifications.
  pointsOfInterest,

  /// Public transport classification, based on stops and stations.
  publicTransport,

  /// Walking service used to determine a user mobility timeline.
  walking,

  /// Annotates [walking] timeline with locations. May have high battery use.
  walkingLocation,
}
