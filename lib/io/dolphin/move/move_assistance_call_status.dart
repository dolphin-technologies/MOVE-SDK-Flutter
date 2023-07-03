/// A status returned by `initiateAssistanceCall()`
enum MoveAssistanceCallStatus {
  /// The call was successfully sent to the backend.
  success,

  /// The SDK was not setup with the required service
  /// (`MoveDetectionService.assistanceCall`).
  initializationError,

  /// The call could not be sent to the server.
  networkError,
}
