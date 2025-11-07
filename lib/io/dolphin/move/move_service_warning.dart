import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:collection/collection.dart';

/// Warnings returned by service warnings listener:
/// `Stream<List<MoveServiceWarning>> setServiceWarningListener()`.
/// A warning indicates a `MoveDetectionService` is missing permissions for complete data collection.
class MoveServiceWarning {
  /// `MoveDetectionService`.
  final MoveDetectionService? service;

  /// Reason indicates a missing permission.
  final List<MoveWarning> reasons;

  const MoveServiceWarning({
    required this.service,
    required this.reasons,
  });

  static List<MoveServiceWarning> fromNative(warnings) {
    List<MoveServiceWarning> moveWarnings = [];
    for (var warning in warnings) {
      String service = warning["service"];
      List reasons = warning["reasons"];

      MoveDetectionService? targetService = MoveDetectionService.values
          .firstWhereOrNull(
              (element) => element.name.toLowerCase() == service.toLowerCase());

      List<MoveWarning> targetReasons = [];
      Iterable mapped = reasons.map((e) {
        MoveWarning? value = MoveWarning.values.firstWhereOrNull(
          (element) => element.name.toLowerCase() == e.toLowerCase(),
        );
        return value;
      });
      Iterable<MoveWarning> filtered = mapped.whereType<MoveWarning>();
      List<MoveWarning> resultList = filtered.toList();
      targetReasons = resultList;

      moveWarnings.add(MoveServiceWarning(
        service: targetService,
        reasons: targetReasons,
      ));
    }
    return moveWarnings;
  }
}

/// Warnings returned by service warnings listener:
/// `Stream<List<MoveServiceError>> setServiceErrorListener()`.
/// A warning indicates a `MoveDetectionService` is missing permissions to work,
/// or is not available for this product.
class MoveServiceError {
  /// `MoveDetectionService`.
  final MoveDetectionService service;

  /// Reason indicates a missing permission or `unauthorized`.
  final List<MoveError> reasons;

  const MoveServiceError({
    required this.service,
    required this.reasons,
  });

  static List<MoveServiceError> fromNative(errors) {
    List<MoveServiceError> moveWarnings = [];
    for (var warning in errors) {
      String service = warning["service"];
      List reasons = warning["reasons"];

      MoveDetectionService? targetService = MoveDetectionService.values
          .firstWhereOrNull(
              (element) => element.name.toLowerCase() == service.toLowerCase());

      if (targetService != null) {
        List<MoveError> targetReasons = reasons
            .map((e) {
              var entry = MoveError.values.firstWhereOrNull(
                (element) => element.name.toLowerCase() == e.toLowerCase(),
              );
              if (entry == null) {
                print("error $e unknown");
              }
              return entry;
            })
            .whereNotNullable()
            .toList();
        moveWarnings.add(MoveServiceError(
          service: targetService,
          reasons: targetReasons,
        ));
      }
    }
    return moveWarnings;
  }
}

extension NotNullIterable<E> on Iterable<E?> {
  Iterable<E> whereNotNullable() => whereType<E>();
}

/// Service warning may impact the quality of a configured service.
enum MoveWarning {
  activityPermissionMissing,
  backgroundLocationPermissionMissing,
  backgroundRestricted,
  batteryOptimization,
  bluetoothConnectPermissionMissing,
  bluetoothPermissionMissing,
  bluetoothScanPermissionMissing,
  bluetoothTurnedOff,
  energySaver,
  fineLocationPermissionMissing,
  goEdition,
  googlePlayLocationAccuracyMissing,
  gpsOff,
  locationMode,
  locationPowerMode,
  mockProvider,
  mockProviderLocation,
  noSim,
  notificationPermissionMissing,
  offline,
  playServicesMissing,
  rooted,
}

/// Error indicating failure of a service.
enum MoveError {
  accelerometerMissing,
  activityPermissionMissing,
  backgroundLocationPermissionMissing,
  batteryPermissionMissing,
  bluetoothScanPermissionMissing,
  googlePlayLocationAccuracyMissing,
  gyroscopeMissing,
  healthConnectReadStepsPermissionMissing,
  healthConnectBackgroundReadStepsPermissionMissing,
  internetPermissionMissing,
  locationPermissionMissing,
  motionPermissionMissing,
  notificationMissing,
  phonePermissionMissing,
  preciseLocationPermissionMissing,
  overlayPermissionMissing,
  unauthorized,
}
