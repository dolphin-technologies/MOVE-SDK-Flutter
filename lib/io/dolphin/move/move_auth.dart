/// An auth object passed to `setup(...)`.
/// This data is prepared by the app backend.
class MoveAuth {
  /// The project id for the app in the MOVE dashboard.
  String projectId;

  /// The user id to uniquely identify the user with.
  String userId;

  /// A jwt token used for the network session. Expires regularily.
  String accessToken;

  /// A jwt token for the SDK to fetch a new access token. When it expires
  /// the auth state listener will be notified with `MoveAuthState.expired`.
  String refreshToken;

  MoveAuth(this.projectId, this.userId, this.accessToken, this.refreshToken);
}
