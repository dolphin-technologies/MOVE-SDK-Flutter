import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:movesdk/io/dolphin/move/move_assistance_call_status.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_error.dart';
import 'package:movesdk/io/dolphin/move/move_auth_result.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_device.dart';
import 'package:movesdk/io/dolphin/move/move_geocode_result.dart';
import 'package:movesdk/io/dolphin/move/move_options.dart';
import 'package:movesdk/io/dolphin/move/move_scan_result.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_shutdown_result.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';
import 'package:collection/collection.dart';
import 'package:movesdk/movesdk.dart';

import 'io/dolphin/move/move_notification.dart';
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
  final tripStartChannel = const EventChannel('movesdk-tripStart');
  final serviceErrorChannel = const EventChannel('movesdk-serviceError');
  final serviceWarningChannel = const EventChannel('movesdk-serviceWarning');
  final deviceDiscoveryChannel = const EventChannel('movesdk-deviceDiscovery');
  final deviceScannerChannel = const EventChannel('movesdk-deviceScanner');
  final deviceStateChannel = const EventChannel('movesdk-deviceState');
  final configChangeChannel = const EventChannel('movesdk-configChange');

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
  Stream<DateTime> setTripStartListener() async* {
    yield* tripStartChannel
        .receiveBroadcastStream()
        .asyncMap<DateTime>((tripStart) {
      return DateTime.fromMillisecondsSinceEpoch(tripStart);
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
  Stream<List<MoveDevice>> startScanningDevices(
      {List<MoveDeviceFilter> filter = const [MoveDeviceFilter.paired],
      String? uuid,
      int? manufacturerId}) async* {
    var filters = filter.map((e) => e.name).toList();
    yield* deviceScannerChannel.receiveBroadcastStream(<String, dynamic>{
      'filter': filters,
      'uuid': uuid,
      'manufacturerId': manufacturerId
    }).asyncMap<List<MoveDevice>>((devices) {
      var result = MoveDevice.fromNative(devices);
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
  Stream<MoveConfig> setRemoteConfigChangeListener() async* {
    yield* configChangeChannel
        .receiveBroadcastStream()
        .asyncMap<MoveConfig>((result) {
      return MoveConfig.fromNative(result);
    });
  }

  @override
  Future<void> setup(
      MoveAuth moveAuth, MoveConfig moveConfig, MoveOptions? options) async {
    await methodChannel.invokeMethod(
      'setup',
      <String, dynamic>{
        'projectId': moveAuth.projectId,
        'accessToken': moveAuth.accessToken,
        'userId': moveAuth.userId,
        'refreshToken': moveAuth.refreshToken,
        'config': moveConfig.buildConfigParameter(),
        'options': <String, dynamic>{
          'motionPermissionMandatory': options?.motionPermissionMandatory,
          'backgroundLocationPermissionMandatory':
              options?.backgroundLocationPermissionMandatory,
          'deviceDiscovery': <String, dynamic>{
            'startDelay': options?.deviceDiscovery?.startDelay,
            'duration': options?.deviceDiscovery?.duration,
            'interval': options?.deviceDiscovery?.interval,
            'stopScanOnFirstDiscovered':
                options?.deviceDiscovery?.stopScanOnFirstDiscovered,
          },
          'useBackendConfig': options?.useBackendConfig,
        },
      },
    );
  }

  @override
  Future<MoveAuthResult> setupWithCode(
      String authCode, MoveConfig moveConfig, MoveOptions? options) async {
    try {
      await methodChannel.invokeMethod(
        'setupWithCode',
        <String, dynamic>{
          'authCode': authCode,
          'config': moveConfig.buildConfigParameter(),
          'options': <String, dynamic>{
            'motionPermissionMandatory': options?.motionPermissionMandatory,
            'backgroundLocationPermissionMandatory':
                options?.backgroundLocationPermissionMandatory,
            'deviceDiscovery': <String, dynamic>{
              'startDelay': options?.deviceDiscovery?.startDelay,
              'duration': options?.deviceDiscovery?.duration,
              'interval': options?.deviceDiscovery?.interval,
              'stopScanOnFirstDiscovered':
                  options?.deviceDiscovery?.stopScanOnFirstDiscovered,
            },
            'useBackendConfig': options?.useBackendConfig,
          },
        },
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case "networkError":
          return MoveAuthResult(AuthSetupStatus.networkError, e.details ?? "");
        case "invalidCode":
          return MoveAuthResult(AuthSetupStatus.invalidCode, e.details ?? "");
      }
    }

    return MoveAuthResult(AuthSetupStatus.success, "");
  }

  @override
  Future<void> updateConfig(MoveConfig config) async {
    await methodChannel.invokeMethod(
      'updateConfig',
      <String, dynamic>{
        'config': config.buildConfigParameter(),
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

  @Deprecated("Shutdown SDK instead.")
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
  Future<bool> startAutomaticDetection() async {
    var result = await methodChannel.invokeMethod('startAutomaticDetection');
    return result;
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
  Future<bool> stopAutomaticDetection() async {
    var result = await methodChannel.invokeMethod('stopAutomaticDetection');
    return result;
  }

  @override
  Future<String> getDeviceQualifier() async {
    final result =
        await methodChannel.invokeMethod<String>('getDeviceQualifier');
    return result ?? "";
  }

  @override
  Future<void> registerDevices(List<MoveDevice> devices) async {
    var deviceMap = {for (var device in devices) device.name: device.data};
    await methodChannel.invokeMethod(
        'registerDevices', <String, dynamic>{'devices': deviceMap});
  }

  @override
  Future<void> unregisterDevices(List<MoveDevice> devices) async {
    var deviceMap = {for (var device in devices) device.name: device.data};
    await methodChannel.invokeMethod(
        'unregisterDevices', <String, dynamic>{'devices': deviceMap});
  }

  @override
  Future<List<MoveDevice>> getRegisteredDevices() async {
    List<dynamic> devices = await methodChannel
            .invokeMethod<List<dynamic>>('getRegisteredDevices') ??
        [];
    var result = MoveDevice.fromNative(devices);
    return result;
  }

  @override
  Stream<List<MoveScanResult>> setDeviceDiscoveryListener() async* {
    yield* deviceDiscoveryChannel
        .receiveBroadcastStream()
        .asyncMap<List<MoveScanResult>>((results) {
      var moveScanResults = MoveScanResult.fromNative(results);
      return moveScanResults;
    });
  }

  @override
  Stream<List<MoveDevice>> setDeviceStateListener() async* {
    yield* deviceStateChannel
        .receiveBroadcastStream()
        .asyncMap<List<MoveDevice>>((results) {
      var moveScanResults = MoveDevice.fromNative(results);
      return moveScanResults;
    });
  }

  Future<dynamic> callbackHandler(MethodCall methodCall) async {
    print('$methodCall.method');
    switch (methodCall.method) {
      default:
        throw MissingPluginException('notImplemented');
    }
  }

  @override
  Future<void> recognitionNotification(MoveNotification notification) async {
    var map = {
      "channelId": notification.channelId,
      "channelName": notification.channelName,
      "channelDescription": notification.channelDescription,
      "contentTitle": notification.contentTitle,
      "contentText": notification.contentText,
      "imageName": notification.imageName,
    };
    await methodChannel.invokeMethod(
        'recognitionNotification', <String, dynamic>{'notification': map});
  }

  @override
  Future<void> tripNotification(MoveNotification notification) async {
    var map = {
      "channelId": notification.channelId,
      "channelName": notification.channelName,
      "channelDescription": notification.channelDescription,
      "contentTitle": notification.contentTitle,
      "contentText": notification.contentText,
      "imageName": notification.imageName,
    };
    await methodChannel.invokeMethod(
        'tripNotification', <String, dynamic>{'notification': map});
  }

  @override
  Future<void> walkingLocationNotification(
      MoveNotification notification) async {
    var map = {
      "channelId": notification.channelId,
      "channelName": notification.channelName,
      "channelDescription": notification.channelDescription,
      "contentTitle": notification.contentTitle,
      "contentText": notification.contentText,
      "imageName": notification.imageName,
    };
    await methodChannel.invokeMethod(
        'walkingLocationNotification', <String, dynamic>{'notification': map});
  }

  @override
  Future<bool> startTrip(Map<String, String>? metadata) async {
    var result = await methodChannel
        .invokeMethod('startTrip', <String, dynamic>{'metadata': metadata});
    return result;
  }

  @override
  Future<bool> setLiveLocationTag(String? tag) async {
    var result = await methodChannel
        .invokeMethod('setLiveLocationTag', <String, dynamic>{'tag': tag});
    return result;
  }
}
