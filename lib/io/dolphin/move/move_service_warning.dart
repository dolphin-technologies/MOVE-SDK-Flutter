import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:collection/collection.dart';

class MoveServiceWarning {
  final MoveDetectionService? service;
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
          .firstWhereOrNull((element) => element.name.toLowerCase() == service.toLowerCase());

      List<MoveWarning> targetReasons = reasons
          .map((e) => MoveWarning.values
              .firstWhere((element) => element.name.toLowerCase() == e.toLowerCase()))
          .toList();

      moveWarnings.add(MoveServiceWarning(
        service: targetService,
        reasons: targetReasons,
      ));
    }
    return moveWarnings;
  }
}

class MoveServiceError {
  final MoveDetectionService service;
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
          .firstWhereOrNull((element) => element.name.toLowerCase() == service.toLowerCase());

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

enum MoveWarning {
  activityPermissionMissing,
  backgroundLocationPermissionMissing,
  batteryOptimization,
  bluetoothPermissionMissing,
  energySaver,
  goEdition,
  gpsOff,
  locationMode,
  locationPowerMode,
  mockProvider,
  mockProviderLocation,
  noSim,
  offline,
  playServicesMissing,
  rooted,
}

enum MoveError {
  accelerometerMissing,
  activityPermissionMissing,
  motionPermissionMissing,
  batteryPermissionMissing,
  gyroscopeMissing,
  internetPermissionMissing,
  locationPermissionMissing,
  notificationMissing,
  phonePermissionMissing,
  preciseLocationPermissionMissing,
  overlayPermissionMissing,
  unauthorized,
}
