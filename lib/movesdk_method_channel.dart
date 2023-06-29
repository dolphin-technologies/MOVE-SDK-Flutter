import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:movesdk/io/dolphin/move/move_assistance_call_status.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_error.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_geocode_result.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_shutdown_result.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';
import 'package:collection/collection.dart';
import 'package:movesdk/movesdk.dart';

import 'movesdk_platform_interface.dart';

/// An implementation of [MovesdkPlatform] that uses method channels.
class MethodChannelMoveSdk extends MovesdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('movesdk');

  final authStateChannel = const EventChannel('movesdk-authState');
  final logChannel = const EventChannel('movesdk-log');
  final sdkStateChannel = const EventChannel('movesdk-sdkState');
  final tripStateChannel = const EventChannel('movesdk-tripState');
  final serviceErrorChannel = const EventChannel('movesdk-serviceError');
  final serviceWarningChannel = const EventChannel('movesdk-serviceWarning');

  MethodChannelMoveSdk() {
    methodChannel.setMethodCallHandler(callbackHandler);
  }

  @override
  Future<String> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version ?? "";
  }

  @override
  Future<String> getMoveVersion() async {
    final version = await methodChannel.invokeMethod<String>('getMoveVersion');
    return version ?? "";
  }

  @override
  Future<void> init() async {
    await methodChannel.invokeMethod('init');
  }

  @override
  Future<bool> synchronizeUserData() async {
    final result =
        await methodChannel.invokeMethod<bool>('synchronizeUserData');
    return result ?? false;
  }

  @override
  Future<void> fetchUserConfig() async {
    await methodChannel.invokeMethod('fetchUserConfig');
  }

  @override
  Future<MoveAssistanceCallStatus> initiateAssistanceCall() async {
    try {
      await methodChannel.invokeMethod('initiateAssistanceCall');
    } on PlatformException catch (e) {
      switch (e.code) {
        case "networkError":
          return MoveAssistanceCallStatus.networkError;
        case "initializationError":
          return MoveAssistanceCallStatus.initializationError;
      }
    }

    return MoveAssistanceCallStatus.success;
  }

  @override
  Future<void> setAssistanceMetaData(String? assistanceMetadataValue) async {
    await methodChannel.invokeMethod(
      'setAssistanceMetaData',
      <String, dynamic>{
        'assistanceMetadataValue': assistanceMetadataValue,
      },
    );
  }

  @override
  Future<void> updateConfig(MoveConfig config) async {
    await methodChannel.invokeMethod(
      'updateConfig',
      <String, List<String>>{
        'moveDetectionServices':
            config.moveDetectionServices.map((e) => e.name).toList(),
      },
    );
  }

  @override
  Stream<MoveState> setSdkStateListener() async* {
    yield* sdkStateChannel
        .receiveBroadcastStream()
        .asyncMap<MoveState>((sdkState) {
      MoveState? result = MoveState.values.firstWhereOrNull(
          (element) => element.name.toLowerCase() == sdkState.toLowerCase());
      return result ?? MoveState.unknown;
    });
  }

  @override
  Stream<MoveAuthState> setAuthStateListener() async* {
    yield* authStateChannel
        .receiveBroadcastStream()
        .asyncMap<MoveAuthState>((authState) {
      MoveAuthState? result = MoveAuthState.values.firstWhereOrNull(
          (element) => element.name.toLowerCase() == authState.toLowerCase());
      return result ?? MoveAuthState.unknown;
    });
  }

  @override
  Stream<String> setLogListener() async* {
    yield* logChannel.receiveBroadcastStream().asyncMap<String>((messageInfo) {
      return "${messageInfo[0]} [${messageInfo[1]}]";
    });
  }

  @override
  Stream<MoveTripState> setTripStateListener() async* {
    yield* tripStateChannel
        .receiveBroadcastStream()
        .asyncMap<MoveTripState>((tripState) {
      MoveTripState? result = MoveTripState.values.firstWhereOrNull(
          (element) => element.name.toLowerCase() == tripState.toLowerCase());
      return result ?? MoveTripState.unknown;
    });
  }

  @override
  Stream<List<MoveServiceWarning>> setServiceWarningListener() async* {
    yield* serviceWarningChannel
        .receiveBroadcastStream()
        .asyncMap<List<MoveServiceWarning>>((warnings) {
      var result = MoveServiceWarning.fromNative(warnings);
      return result;
    });
  }

  @override
  Stream<List<MoveServiceError>> setServiceErrorListener() async* {
    yield* serviceErrorChannel
        .receiveBroadcastStream()
        .asyncMap<List<MoveServiceError>>((warnings) {
      var result = MoveServiceError.fromNative(warnings);
      return result;
    });
  }

  @override
  Future<void> setup(MoveAuth moveAuth, MoveConfig moveConfig) async {
    await methodChannel.invokeMethod(
      'setup',
      <String, dynamic>{
        'projectId': moveAuth.projectId,
        'accessToken': moveAuth.accessToken,
        'userId': moveAuth.userId,
        'refreshToken': moveAuth.refreshToken,
        'config': moveConfig.moveDetectionServices
            .map((e) => e.toString().split('.').last)
            .toList()
      },
    );
  }

  @override
  Future<MoveShutdownResult> shutdown({bool force = true}) async {
    try {
      await methodChannel.invokeMethod(
        'shutdown',
        <String, dynamic>{
          'force': force,
        },
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case "uninitialized":
          return MoveShutdownResult.uninitialized;
        case "networkError":
          return MoveShutdownResult.networkError;
      }
    }

    return MoveShutdownResult.success;
  }

  @override
  Future<void> deleteLocalData() async {
    await methodChannel.invokeMethod('deleteLocalData');
  }

  @override
  Future<MoveAuthError?> updateAuth(MoveAuth moveAuth) async {
    try {
      await methodChannel.invokeMethod(
        'updateAuth',
        <String, dynamic>{
          'projectId': moveAuth.projectId,
          'accessToken': moveAuth.accessToken,
          'userId': moveAuth.userId,
          'refreshToken': moveAuth.refreshToken,
        },
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case "authInvalid":
          return MoveAuthError.authInvalid;
        case "serviceUnreachable":
          return MoveAuthError.serviceUnreachable;
        case "throttle":
          return MoveAuthError.throttle;
      }
    }

    return null;
  }

  @override
  Future<void> allowMockLocations(bool allow) async {
    await methodChannel.invokeMethod(
      'allowMockLocations',
      <String, dynamic>{
        'allow': allow,
      },
    );
  }

  @override
  Future<void> resolveError() async {
    await methodChannel.invokeMethod('resolveError');
  }

  @override
  Future<void> keepInForeground(bool enabled) async {
    await methodChannel.invokeMethod(
      'keepInForeground',
      <String, dynamic>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<void> keepActive(bool enabled) async {
    await methodChannel.invokeMethod(
      'keepActive',
      <String, dynamic>{
        'enabled': enabled,
      },
    );
  }

  @override
  Future<void> startAutomaticDetection() async {
    await methodChannel.invokeMethod('startAutomaticDetection');
  }

  @override
  Future<void> forceTripRecognition() async {
    await methodChannel.invokeMethod('forceTripRecognition');
  }

  @override
  Future<void> finishCurrentTrip() async {
    await methodChannel.invokeMethod('finishCurrentTrip');
  }

  @override
  Future<void> ignoreCurrentTrip() async {
    await methodChannel.invokeMethod('ignoreCurrentTrip');
  }

  @override
  Future<MoveGeocodeResult> geocode(double latitude, double longitude) async {
    try {
      final result = await methodChannel.invokeMethod<String>('geocode',
          <String, double>{'latitude': latitude, 'longitude': longitude});
      return MoveGeocodeResult(result, null);
    } on PlatformException catch (e) {
      switch (e.code) {
        case "thresholdReached":
          return MoveGeocodeResult(null, MoveGeocodeError.thresholdReached);
        case "serviceUnreachable":
          return MoveGeocodeResult(null, MoveGeocodeError.serviceUnreachable);
        default:
          return MoveGeocodeResult(null, MoveGeocodeError.resolveFailed);
      }
    }
  }

  @override
  Future<MoveState> getState() async {
    final sdkState = await methodChannel.invokeMethod<String>('getSdkState');
    MoveState? result = MoveState.values.firstWhereOrNull(
        (element) => element.name.toLowerCase() == sdkState?.toLowerCase());
    return result ?? MoveState.unknown;
  }

  @override
  Future<MoveTripState> getTripState() async {
    final tripState = await methodChannel.invokeMethod<String>('getTripState');
    MoveTripState? result = MoveTripState.values.firstWhereOrNull(
        (element) => element.name.toLowerCase() == tripState?.toLowerCase());
    return result ?? MoveTripState.unknown;
  }

  @override
  Future<MoveAuthState> getAuthState() async {
    final authState = await methodChannel.invokeMethod<String>('getAuthState');
    MoveAuthState? result = MoveAuthState.values.firstWhereOrNull(
        (element) => element.name.toLowerCase() == authState?.toLowerCase());
    return result ?? MoveAuthState.unknown;
  }

  @override
  Future<List<MoveServiceWarning>> getWarnings() async {
    final warnings =
        await methodChannel.invokeMethod<List<dynamic>>('getWarnings') ?? [];
    var result = MoveServiceWarning.fromNative(warnings);
    return result;
  }

  @override
  Future<List<MoveServiceError>> getErrors() async {
    List<dynamic> errors =
        await methodChannel.invokeMethod<List<dynamic>>('getErrors') ?? [];
    var result = MoveServiceError.fromNative(errors);
    return result;
  }

  @override
  Future<void> stopAutomaticDetection() async {
    await methodChannel.invokeMethod('stopAutomaticDetection');
  }

  @override
  Future<String> getDeviceQualifier() async {
    final result =
        await methodChannel.invokeMethod<String>('getDeviceQualifier');
    return result ?? "";
  }

  Future<dynamic> callbackHandler(MethodCall methodCall) async {
    print('$methodCall.method');
    switch (methodCall.method) {
      default:
        throw MissingPluginException('notImplemented');
    }
  }
}
