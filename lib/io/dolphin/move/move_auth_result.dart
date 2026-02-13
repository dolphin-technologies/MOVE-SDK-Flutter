/// An error status used in `MoveAuthResult`
enum AuthSetupStatus {
  success,

  /// A network error occurred.
  networkError,

  /// Auth code is invalid.
  invalidCode,
}

/// An error returned by `setup(String authCode, ...)`
class MoveAuthResult {
  /// Authentication status.
  AuthSetupStatus status;

  /// Status message.
  String description;

  MoveAuthResult(this.status, this.description);
}
