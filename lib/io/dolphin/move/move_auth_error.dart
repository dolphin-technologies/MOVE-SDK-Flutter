/// An error returned by `updateAuth(MoveAuth auth)`
enum MoveAuthError {
  /// The userId does not match the one passed in setup.
  authInvalid,

  /// `updateAuth(MoveAuth auth)` was called too often.
  throttle,

  /// The validity of the token could not be confirmed, the SDK will retry at a later time.
  serviceUnreachable,
}
