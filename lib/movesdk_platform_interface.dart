import 'package:movesdk/io/dolphin/move/move_assistance_call_status.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_error.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_geocode_result.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_shutdown_result.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';
import 'package:movesdk/movesdk.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'movesdk_method_channel.dart';

abstract class MovesdkPlatform extends PlatformInterface {
  /// Constructs a MovesdkPlatform.
  MovesdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static MovesdkPlatform _instance = MethodChannelMoveSdk();

  /// The default instance of [MovesdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelMoveSdk].
  static MovesdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MovesdkPlatform] when
  /// they register themselves.
  static set instance(MovesdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<String> getMoveVersion() {
    throw UnimplementedError('getMoveVersion() has not been implemented.');
  }

  Future<String> getDeviceQualifier() {
    throw UnimplementedError('getDeviceQualifier() has not been implemented.');
  }

  Future<MoveAuthError?> updateAuth(MoveAuth moveAuth) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> init() {
    throw UnimplementedError('setup has not been implemented.');
  }

  Future<void> setup(MoveAuth moveAuth, MoveConfig moveConfig) {
    throw UnimplementedError('setup has not been implemented.');
  }

  Future<void> startAutomaticDetection() {
    throw UnimplementedError('startAutomaticDetection() has not been implemented.');
  }

  Future<void> stopAutomaticDetection() {
    throw UnimplementedError('stopAutomaticDetection() has not been implemented.');
  }

  Future<MoveShutdownResult> shutdown({bool force = true}) {
    throw UnimplementedError('shutdown() has not been implemented.');
  }

  Future<void> deleteLocalData() {
    throw UnimplementedError('shutdown() has not been implemented.');
  }

  Future<void> forceTripRecognition() {
    throw UnimplementedError('forceTripRecognition() has not been implemented.');
  }

  Future<void> ignoreCurrentTrip() {
    throw UnimplementedError('ignoreCurrentTrip() has not been implemented.');
  }

  Future<void> finishCurrentTrip() {
    throw UnimplementedError('finishCurrentTrip() has not been implemented.');
  }

  Future<void> allowMockLocations(bool allow) async {
    throw UnimplementedError('allowMockLocations() has not been implemented.');
  }

  Future<bool> synchronizeUserData() {
    throw UnimplementedError('synchronizeUserData() has not been implemented.');
  }

  Future<void> fetchUserConfig() {
    throw UnimplementedError('fetchUserConfig() has not been implemented.');
  }

  Future<void> updateConfig(MoveConfig config) {
    throw UnimplementedError('updateConfiguration(config) has not been implemented.');
  }

  Future<MoveAssistanceCallStatus> initiateAssistanceCall() {
    throw UnimplementedError('initiateAssistanceCall() has not been implemented.');
  }

  Future<void> setAssistanceMetaData(String? assistanceMetadataValue) {
    throw UnimplementedError('setAssistanceMetaData() has not been implemented.');
  }

  Future<MoveGeocodeResult> geocode(double latitude, double longitude) {
    throw UnimplementedError('geocode() has not been implemented.');
  }

  Future<MoveState> getState() {
    throw UnimplementedError('getState() has not been implemented.');
  }

  Future<MoveTripState> getTripState() {
    throw UnimplementedError('getTripState() has not been implemented.');
  }

  Future<MoveAuthState> getAuthState() {
    throw UnimplementedError('getTripState() has not been implemented.');
  }

  Future<List<MoveServiceWarning>> getWarnings() {
    throw UnimplementedError('getWarnings() has not been implemented.');
  }

  Future<List<MoveServiceError>> getErrors() {
    throw UnimplementedError('getErrors() has not been implemented.');
  }

  /// Android only
  Future<void> keepInForeground(bool enabled) {
    throw UnimplementedError('keepInForeground() has not been implemented.');
  }

  /// Android only
  Future<void> keepActive(bool enabled) {
    throw UnimplementedError('keepActive() has not been implemented.');
  }

  /// Android only
  Future<void> resolveError() {
    throw UnimplementedError('resolveError() has not been implemented.');
  }

  Stream<MoveAuthState> setAuthStateListener() async* {
    throw UnimplementedError('setAuthStateListener() has not been implemented.');
  }

  Stream<String> setLogListener() async* {
    throw UnimplementedError('setLogListener() has not been implemented.');
  }

  Stream<MoveState> setSdkStateListener() async* {
    throw UnimplementedError('setSdkStateListener() has not been implemented.');
  }

  Stream<MoveTripState> setTripStateListener() async* {
    throw UnimplementedError('setTripStateListener() has not been implemented.');
  }

  Stream<List<MoveServiceWarning>> setServiceWarningListener() async* {
    throw UnimplementedError('setServiceWarningListener() has not been implemented.');
  }

  Stream<List<MoveServiceError>> setServiceErrorListener() async* {
    throw UnimplementedError('setServiceErrorListener() has not been implemented.');
  }
}
