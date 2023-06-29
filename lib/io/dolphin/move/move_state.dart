// Move SDK state, persisted.
enum MoveState {
  /// SDK was setup. User was authenticated.
  ready,

  /// SDK in `startAutomaticDetection()` state. Services are running.
  running,

  /// SDK was not setup or it was shutdown.
  unknown,
}
