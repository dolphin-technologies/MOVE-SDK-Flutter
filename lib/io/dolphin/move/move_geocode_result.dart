enum MoveGeocodeError {
  resolveFailed,
  thresholdReached,
  serviceUnreachable,
}

class MoveGeocodeResult {
  String? result;
  MoveGeocodeError? error;

  MoveGeocodeResult(
    this.result,
    this.error,
  );
}
