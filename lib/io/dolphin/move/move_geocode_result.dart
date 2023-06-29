/// Error from `geocode(latitude, longitude)`.
enum MoveGeocodeError {
  /// Geocode API returned an error.
  resolveFailed,

  /// Geocode API hit a throttle and fallback called too often.
  thresholdReached,

  /// Server could not be contacted for fallback.
  serviceUnreachable,
}

/// Result from `geocode(latitude, longitude)`.
/// Returns address in [result] or an [error].
class MoveGeocodeResult {
  /// Address of looked up coordinates.
  String? result;

  /// Lookup could not be completed.
  MoveGeocodeError? error;

  MoveGeocodeResult(
    this.result,
    this.error,
  );
}
