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

  /// Get Move SDK Version.
  /// Returns a version string.
  Future<String> getMoveVersion() {
    throw UnimplementedError('getMoveVersion() has not been implemented.');
  }

  /// Get a unique Device Identifier to distinguish the device.
  /// This changes when a device is cloned.
  /// Returns a unique device identifier.
  Future<String> getDeviceQualifier() {
    throw UnimplementedError('getDeviceQualifier() has not been implemented.');
  }

  /// Updates the user's provided Auth upon its expiry. Auth expiry triggers
  /// the SDK Auth State change listener.
  ///
  /// Warning:
  /// - Only the user's token is expected to update. Changing any other
  ///   user's auth param will fail with `MoveAuthError.authInvalid`.
  /// [moveAuth] must contain new valid authentication data.
  /// Returns an errror if failed.
  Future<MoveAuthError?> updateAuth(MoveAuth moveAuth) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> init() {
    throw UnimplementedError('setup has not been implemented.');
  }

  /// The SDK will setup and authenticate a user.
  /// [moveAuth] contains authentication data and tokens prepared by the app backend..
  /// [moveConfig] indicates the configuration of the services which will be running.
  /// Services in [moveConfig] must be enabled in the MOVE dashboard.
  Future<void> setup(MoveAuth moveAuth, MoveConfig moveConfig) {
    throw UnimplementedError('setup has not been implemented.');
  }

  /// Starts the required detection services stated in the Config that is passed on init.
  /// Starting the service will set the SDK to running state.
  /// Precondition:
  /// - SDK State to be `.ready`.
  Future<void> startAutomaticDetection() {
    throw UnimplementedError(
        'startAutomaticDetection() has not been implemented.');
  }

  /// Stops the automatic detection service.
  /// Stoping the service will set the SDK State back to ready.
  /// Precondition:
  /// - SDK State to be `.running`.
  Future<void> stopAutomaticDetection() {
    throw UnimplementedError(
        'stopAutomaticDetection() has not been implemented.');
  }

  /// Shutdown SDK shared instance.
  ///
  /// Stops SDK services, sends the queued user data, and de-intialized the SDK.
  /// After that is executed, the SDK State.uninitialized is triggered.
  /// The [force] parameter (default: `true`) will discard pending data to be uploaded.
  /// With [force] = true shudown will always succseed.
  /// Returns when shutdown completed or failed.
  Future<MoveShutdownResult> shutdown({bool force = true}) {
    throw UnimplementedError('shutdown() has not been implemented.');
  }

  /// Deletes all the collected user SDK data stored on the device.
  ///
  /// This doesn't affect the SDK state.
  Future<void> deleteLocalData() {
    throw UnimplementedError('shutdown() has not been implemented.');
  }

  /// Temporarily calibrates the SDK to highest detection mode.
  ///
  /// In order to optimise battery consumption, the SDK goes through different
  /// detection modes with different battery consumptions levels, depending on
  /// the user's current behaviour and activity. In general the SDK is
  /// responsible for alternating between those different detection modes.
  ///
  /// The SDK also provides hosting apps this API to call if they has their own
  /// reasons (like sensors or beacons) to believe that the user is starting a
  /// trip. This will make sure the SDK is on the highest detecting state to
  /// detect the trip faster.
  ///
  /// Precondition:
  /// - SDK State to be `.running`.
  Future<void> forceTripRecognition() {
    throw UnimplementedError(
        'forceTripRecognition() has not been implemented.');
  }

  /// Ignores the current ongoing trip.
  ///
  /// This API will set the ongoing TripState to .ignored.
  /// Ignored trips data are purged and not sent to the server.
  ///
  /// Precondition:
  /// - SDK should be in an active trip.
  Future<void> ignoreCurrentTrip() {
    throw UnimplementedError('ignoreCurrentTrip() has not been implemented.');
  }

  /// Ends the current ongoing trip.
  ///
  /// This API will end the ongoing trip and set TripState back to .idle.
  /// The SDK is responsible for detecting trip start and end points. The SDK
  /// also provides hosting apps this API to call if they have their own reasons
  /// (like sensors or beacons) to believe that the user's trip has ended.
  ///
  /// Precondition:
  /// - SDK should be in an active trip.
  Future<void> finishCurrentTrip() {
    throw UnimplementedError('finishCurrentTrip() has not been implemented.');
  }

  /// Android only
  Future<void> allowMockLocations(bool allow) async {
    throw UnimplementedError('allowMockLocations() has not been implemented.');
  }

  /// Force sending all pending user data to server.
  /// Preconditions:
  /// - Shouldn't be called more than once per 120 seconds.
  /// - SDK should not be uninitialized.
  /// Returns a result indicating wether there are further trips are in queue
  /// waiting to be uploaded. true means queue is empty.
  Future<bool> synchronizeUserData() {
    throw UnimplementedError('synchronizeUserData() has not been implemented.');
  }

  /// Force fetching config from server.
  Future<void> fetchUserConfig() {
    throw UnimplementedError('fetchUserConfig() has not been implemented.');
  }

  /// The SDK will attempt to change the client [config],
  /// will call warning/error listener respectively.
  Future<void> updateConfig(MoveConfig config) {
    throw UnimplementedError(
        'updateConfiguration(config) has not been implemented.');
  }

  /// Inititate an Assistance Call to emergency services.
  /// Returns a status wether the call succeeded.
  Future<MoveAssistanceCallStatus> initiateAssistanceCall() {
    throw UnimplementedError(
        'initiateAssistanceCall() has not been implemented.');
  }

  /// Set metadata to be sent with assistance call or impact detection.
  Future<void> setAssistanceMetaData(String? assistanceMetadataValue) {
    throw UnimplementedError(
        'setAssistanceMetaData() has not been implemented.');
  }

  /// Geocode address lookup at coordinates: ([latitude], [longitude])
  /// Returns a result with a String at `MoveGeocodeResult.result` or an error with `MoveGeocodeResult.error`.
  Future<MoveGeocodeResult> geocode(double latitude, double longitude) {
    throw UnimplementedError('geocode() has not been implemented.');
  }

  /// Returns the current SDK state.
  Future<MoveState> getState() {
    throw UnimplementedError('getState() has not been implemented.');
  }

  /// Returns the current SDK trip state.
  Future<MoveTripState> getTripState() {
    throw UnimplementedError('getTripState() has not been implemented.');
  }

  /// Returns the current authorization state.
  Future<MoveAuthState> getAuthState() {
    throw UnimplementedError('getTripState() has not been implemented.');
  }

  /// Gets the current SDK warniings
  /// Returns current service state. Empty if all good.
  Future<List<MoveServiceWarning>> getWarnings() {
    throw UnimplementedError('getWarnings() has not been implemented.');
  }

  /// Gets the current SDK failures
  /// Returns current service state. Empty if all good.
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

  /// Resolve standing SDK state error.
  /// Host app should call this API after resolving the raised errors.
  /// SDK will reevaluate the error state and update the SDK state accordingly.
  Future<void> resolveError() {
    throw UnimplementedError('resolveError() has not been implemented.');
  }

  /// Set a block to be invoked every time SDK authorization state changes.
  /// Important:
  /// - Hosting app must handle case `expired` by refetching a new token as
  ///   SDK cannot update the given anymore.
  /// Returns stream: latest MoveAuthState. Invoked every time auth state changes.
  Stream<MoveAuthState> setAuthStateListener() async* {
    throw UnimplementedError(
        'setAuthStateListener() has not been implemented.');
  }

  /// Set callback to be invoked every time a new SDK log event occurs.
  ///
  /// Returns log string. Invoked every time log event occurs.
  Stream<String> setLogListener() async* {
    throw UnimplementedError('setLogListener() has not been implemented.');
  }

  /// Set a block to be invoked every time SDK state changes.
  ///
  /// Important:
  /// - Set this State listener before `initializing` the SDK to
  ///   anticipate the SDK State changes triggered by `initializing` API.
  ///
  /// Returns stream: latest SDK state. Invoked every time SDK state changes.
  Stream<MoveState> setSdkStateListener() async* {
    throw UnimplementedError('setSdkStateListener() has not been implemented.');
  }

  /// Set a block to be invoked every time SDK trip state changes.
  ///
  /// Returns stream: latest SDK trip state. Invoked every time SDK trip state changes.
  Stream<MoveTripState> setTripStateListener() async* {
    throw UnimplementedError(
        'setTripStateListener() has not been implemented.');
  }

  /// Sets a block to get called when optional permissions for
  /// the activated services are missing.
  /// Returns stream: `List<MoveServiceWarning>`. Invoked in case of configuration
  /// or permission errors.
  Stream<List<MoveServiceWarning>> setServiceWarningListener() async* {
    throw UnimplementedError(
        'setServiceWarningListener() has not been implemented.');
  }

  /// Set a block to be invoked every time SDK warning status changes.
  /// When the config passed in `setup(auth:config:)` tries to initialize
  /// services that are not available in the server config those services will
  /// stop and are reported in the to the provided listener.
  /// This is not supposed to happen in a correct setup.
  /// Additionally missing user permissions are also reported.
  /// Returns stream: `List<MoveServiceError>`. Invoked in case of configuration
  /// or permission errors.
  Stream<List<MoveServiceError>> setServiceErrorListener() async* {
    throw UnimplementedError(
        'setServiceErrorListener() has not been implemented.');
  }
}
