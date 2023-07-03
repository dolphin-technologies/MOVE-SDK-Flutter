// Move trip state. Updated by trip state listener:
// `Stream<MoveTripState> setTripStateListener()`.
enum MoveTripState {
  /// SDK uninitialized.
  unknown,

  /// Idle state, trip not detected.
  idle,

  /// Driving state in a trip, at speed.
  driving,

  /// Halt state in a trip at low or no speed.
  halt,

  /// Trip was ignored with `ignoreTrip()` and is waiting to end.
  ignored,
}
