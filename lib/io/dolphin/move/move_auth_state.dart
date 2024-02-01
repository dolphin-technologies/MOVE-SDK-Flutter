/// A state indicating the status, returned by the auth state listener
/// set with `Stream<MoveAuthState> setAuthStateListener()`.
/// Indicates the status of the refresh token. When the state is [invalid]
/// the App needs logout the user with `shutdown()`.
enum MoveAuthState {
  /// Initial state, not verified on the backend.
  unknown,

  /// Deprecated, state will never be expired.
  @Deprecated('obsolete')
  expired,

  /// Tokens are valid.
  valid,

  /// Refresh token is invalid and shutdown must be called.
  invalid,
}
