import 'package:movesdk/io/dolphin/move/move_assistance_call_status.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_error.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:movesdk/io/dolphin/move/move_geocode_result.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_shutdown_result.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';

import 'movesdk_platform_interface.dart';

class MoveConfig {
  List<MoveDetectionService> moveDetectionServices;

  MoveConfig(this.moveDetectionServices);
}

class MoveSdk {
  Future<String> getPlatformVersion() {
    return MovesdkPlatform.instance.getPlatformVersion();
  }

  Future<String> getMoveVersion() {
    return MovesdkPlatform.instance.getMoveVersion();
  }

  Future<void> init() {
    return MovesdkPlatform.instance.init();
  }

  Future<void> setup(MoveAuth auth, MoveConfig moveConfig) {
    return MovesdkPlatform.instance.setup(auth, moveConfig);
  }

  Future<String> getDeviceQualifier() {
    return MovesdkPlatform.instance.getDeviceQualifier();
  }

  Future<MoveAuthError?> updateAuth(MoveAuth auth) {
    return MovesdkPlatform.instance.updateAuth(auth);
  }

  Future<void> startAutomaticDetection() {
    return MovesdkPlatform.instance.startAutomaticDetection();
  }

  Future<void> stopAutomaticDetection() {
    return MovesdkPlatform.instance.stopAutomaticDetection();
  }

  Future<MoveShutdownResult> shutdown({bool force = true}) {
    return MovesdkPlatform.instance.shutdown(force: force);
  }

  Future<void> deleteLocalData() {
    return MovesdkPlatform.instance.deleteLocalData();
  }

  Future<void> forceTripRecognition() {
    return MovesdkPlatform.instance.forceTripRecognition();
  }

  Future<void> ignoreCurrentTrip() {
    return MovesdkPlatform.instance.ignoreCurrentTrip();
  }

  Future<void> finishCurrentTrip() {
    return MovesdkPlatform.instance.finishCurrentTrip();
  }

  Future<bool> synchronizeUserData() {
    return MovesdkPlatform.instance.synchronizeUserData();
  }

  Future<void> updateConfig(MoveConfig config) {
    return MovesdkPlatform.instance.updateConfig(config);
  }

  Future<MoveAssistanceCallStatus> initiateAssistanceCall() {
    return MovesdkPlatform.instance.initiateAssistanceCall();
  }

  Future<void> setAssistanceMetaData(String? assistanceMetadataValue) {
    return MovesdkPlatform.instance.setAssistanceMetaData(assistanceMetadataValue);
  }

  Future<MoveGeocodeResult> geocode(double latitude, double longitude) {
    return MovesdkPlatform.instance.geocode(latitude, longitude);
  }

  Future<MoveState> getState() async {
    return await MovesdkPlatform.instance.getState();
  }

  Future<MoveAuthState> getAuthState() async {
    return await MovesdkPlatform.instance.getAuthState();
  }

  Future<MoveTripState> getTripState() async {
    return await MovesdkPlatform.instance.getTripState();
  }

  Future<List<MoveServiceWarning>> getWarnings() {
    return MovesdkPlatform.instance.getWarnings();
  }

  Future<List<MoveServiceError>> getErrors() {
    return MovesdkPlatform.instance.getErrors();
  }

  // Android only

  Future<void> keepInForeground(bool enabled) {
    return MovesdkPlatform.instance.keepInForeground(enabled);
  }

  Future<void> keepActive(bool enabled) {
    return MovesdkPlatform.instance.keepActive(enabled);
  }

  Future<void> allowMockLocations(bool allow) {
    return MovesdkPlatform.instance.allowMockLocations(allow);
  }

  Future<void> resolveError() {
    return MovesdkPlatform.instance.resolveError();
  }

  // Listeners

  Stream<MoveState> setSdkStateListener() async* {
    yield* MovesdkPlatform.instance.setSdkStateListener();
  }

  Stream<MoveAuthState> setAuthStateListener() async* {
    yield* MovesdkPlatform.instance.setAuthStateListener();
  }

  Stream<String> setLogListener() async* {
    yield* MovesdkPlatform.instance.setLogListener();
  }

  Stream<MoveTripState> setTripStateListener() async* {
    yield* MovesdkPlatform.instance.setTripStateListener();
  }

  Stream<List<MoveServiceWarning>> setServiceWarningListener() async* {
    yield* MovesdkPlatform.instance.setServiceWarningListener();
  }

  Stream<List<MoveServiceError>> setServiceErrorListener() async* {
    yield* MovesdkPlatform.instance.setServiceErrorListener();
  }
}
