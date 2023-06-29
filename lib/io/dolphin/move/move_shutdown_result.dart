/// Result returned by `shutdown(force)`.
enum MoveShutdownResult {
  /// Shutdown succeeded.
  success,

  /// Forced shutdown failed due to inability to upload pending data.
  networkError,

  /// SDK was not initialized.
  uninitialized,
}
