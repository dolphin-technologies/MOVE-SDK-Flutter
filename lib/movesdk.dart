import 'package:movesdk/io/dolphin/move/move_assistance_call_status.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_error.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:movesdk/io/dolphin/move/move_device.dart';
import 'package:movesdk/io/dolphin/move/move_geocode_result.dart';
import 'package:movesdk/io/dolphin/move/move_scan_result.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_shutdown_result.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';

import 'io/dolphin/move/move_options.dart';
import 'movesdk_platform_interface.dart';

/// A list of services passed in `setup(auth, config)` or `updateConfig(config)`.
class MoveConfig {
  List<MoveDetectionService> moveDetectionServices;

  MoveConfig(this.moveDetectionServices);

  Iterable<String> buildConfigParameter() {
    return moveDetectionServices.map((e) => e.toString().split('.').last).toList();
  }
}

/// MOVE SDK API.
class MoveSdk {
  Future<String> getPlatformVersion() {
    return MovesdkPlatform.instance.getPlatformVersion();
  }

  /// Get Move SDK Version.
  /// Returns a version string.
  Future<String> getMoveVersion() {
    return MovesdkPlatform.instance.getMoveVersion();
  }

  Future<void> init() {
    return MovesdkPlatform.instance.init();
  }

  /// The SDK will setup and authenticate a user.
  /// [moveAuth] contains authentication data and tokens prepared by the app backend..
  /// [moveConfig] indicates the configuration of the services which will be running.
  /// Services in [moveConfig] must be enabled in the MOVE dashboard.
  Future<void> setup(MoveAuth auth, MoveConfig moveConfig, {MoveOptions? options}) {
    return MovesdkPlatform.instance.setup(auth, moveConfig, options);
  }

  /// Get a unique Device Identifier to distinguish the device.
  /// This changes when a device is cloned.
  /// Returns a unique device identifier.
  Future<String> getDeviceQualifier() {
    return MovesdkPlatform.instance.getDeviceQualifier();
  }

  /// Updates the user's provided Auth upon its expiry. Auth expiry triggers
  /// the SDK Auth State change listener.
  ///
  /// Warning:
  /// - Only the user's token is expected to update. Changing any other
  ///   user's auth param will fail with `MoveAuthError.authInvalid`.
  /// [moveAuth] must contain new valid authentication data.
  /// Returns an errror if failed.
  Future<MoveAuthError?> updateAuth(MoveAuth auth) {
    return MovesdkPlatform.instance.updateAuth(auth);
  }

  /// Starts the required detection services stated in the Config that is passed on init.
  /// Starting the service will set the SDK to running state.
  /// Precondition:
  /// - SDK State to be `.ready`.
  Future<void> startAutomaticDetection() {
    return MovesdkPlatform.instance.startAutomaticDetection();
  }

  /// Stops the automatic detection service.
  /// Stoping the service will set the SDK State back to ready.
  /// Precondition:
  /// - SDK State to be `.running`.
  Future<void> stopAutomaticDetection() {
    return MovesdkPlatform.instance.stopAutomaticDetection();
  }

  /// Shutdown SDK shared instance.
  ///
  /// Stops SDK services, sends the queued user data, and de-intialized the SDK.
  /// After that is executed, the SDK State.uninitialized is triggered.
  /// The [force] parameter (default: `true`) will discard pending data to be uploaded.
  /// With [force] = true shudown will always succseed.
  /// Returns when shutdown completed or failed.
  Future<MoveShutdownResult> shutdown({bool force = true}) {
    return MovesdkPlatform.instance.shutdown(force: force);
  }

  /// Deletes all the collected user SDK data stored on the device.
  /// This doesn't affect the SDK state.
  Future<void> deleteLocalData() {
    return MovesdkPlatform.instance.deleteLocalData();
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
    return MovesdkPlatform.instance.forceTripRecognition();
  }

  /// Ignores the current ongoing trip.
  ///
  /// This API will set the ongoing TripState to .ignored.
  /// Ignored trips data are purged and not sent to the server.
  ///
  /// Precondition:
  /// - SDK should be in an active trip.
  Future<void> ignoreCurrentTrip() {
    return MovesdkPlatform.instance.ignoreCurrentTrip();
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
    return MovesdkPlatform.instance.finishCurrentTrip();
  }

  /// Force sending all pending user data to server.
  /// Preconditions:
  /// - Shouldn't be called more than once per 120 seconds.
  /// - SDK should not be uninitialized.
  /// Returns a result indicating wether there are further trips are in queue
  /// waiting to be uploaded. true means queue is empty.
  Future<bool> synchronizeUserData() {
    return MovesdkPlatform.instance.synchronizeUserData();
  }

  /// The SDK will attempt to change the client [config],
  /// will call warning/error listener respectively.
  Future<void> updateConfig(MoveConfig config) {
    return MovesdkPlatform.instance.updateConfig(config);
  }

  /// Inititate an Assistance Call to emergency services.
  /// Returns a status wether the call succeeded.
  Future<MoveAssistanceCallStatus> initiateAssistanceCall() {
    return MovesdkPlatform.instance.initiateAssistanceCall();
  }

  /// Set metadata to be sent with assistance call or impact detection.
  Future<void> setAssistanceMetaData(String? assistanceMetadataValue) {
    return MovesdkPlatform.instance.setAssistanceMetaData(assistanceMetadataValue);
  }

  /// Geocode address lookup at coordinates: ([latitude], [longitude])
  /// Returns a result with a String at `MoveGeocodeResult.result` or
  /// an error with `MoveGeocodeResult.error`.
  Future<MoveGeocodeResult> geocode(double latitude, double longitude) {
    return MovesdkPlatform.instance.geocode(latitude, longitude);
  }

  /// Returns the current SDK state.
  Future<MoveState> getState() async {
    return await MovesdkPlatform.instance.getState();
  }

  /// Returns the current authorization state.
  Future<MoveAuthState> getAuthState() async {
    return await MovesdkPlatform.instance.getAuthState();
  }

  /// Returns the current SDK trip state.
  Future<MoveTripState> getTripState() async {
    return await MovesdkPlatform.instance.getTripState();
  }

  /// Gets the current SDK warniings
  /// Returns current service state. Empty if all good.
  Future<List<MoveServiceWarning>> getWarnings() {
    return MovesdkPlatform.instance.getWarnings();
  }

  /// Gets the current SDK failures
  /// Returns current service state. Empty if all good.
  Future<List<MoveServiceError>> getErrors() {
    return MovesdkPlatform.instance.getErrors();
  }

  // Android only

  /// Android only
  Future<void> keepInForeground(bool enabled) {
    return MovesdkPlatform.instance.keepInForeground(enabled);
  }

  /// Android only
  Future<void> keepActive(bool enabled) {
    return MovesdkPlatform.instance.keepActive(enabled);
  }

  /// Android only
  Future<void> allowMockLocations(bool allow) {
    return MovesdkPlatform.instance.allowMockLocations(allow);
  }

  /// Resolve standing SDK state error.
  /// Host app should call this API after resolving the raised errors.
  /// SDK will reevaluate the error state and update the SDK state accordingly.
  Future<void> resolveError() {
    return MovesdkPlatform.instance.resolveError();
  }

  // Listeners

  /// Set a block to be invoked every time SDK state changes.
  /// Important:
  /// - Set this State listener before `initializing` the SDK to
  ///   anticipate the SDK State changes triggered by `initializing` API.
  ///
  /// Returns stream: latest SDK state. Invoked every time SDK state changes.
  Stream<MoveState> setSdkStateListener() async* {
    yield* MovesdkPlatform.instance.setSdkStateListener();
  }

  /// Set a block to be invoked every time SDK authorization state changes.
  /// Important:
  /// - Hosting app must handle case `expired` by refetching a new token as
  ///   SDK cannot update the given anymore.
  /// Returns stream: latest MoveAuthState. Invoked every time auth state changes.
  Stream<MoveAuthState> setAuthStateListener() async* {
    yield* MovesdkPlatform.instance.setAuthStateListener();
  }

  /// Set callback to be invoked every time a new SDK log event occurs.
  /// Returns log string. Invoked every time log event occurs.
  Stream<String> setLogListener() async* {
    yield* MovesdkPlatform.instance.setLogListener();
  }

  /// Set a block to be invoked every time SDK trip state changes.
  /// Returns stream: latest SDK trip state. Invoked every time SDK trip state changes.
  Stream<MoveTripState> setTripStateListener() async* {
    yield* MovesdkPlatform.instance.setTripStateListener();
  }

  /// Sets a block to get called when optional permissions for
  /// the activated services are missing.
  /// Returns stream: `List<MoveServiceWarning>`. Invoked in case of configuration
  /// or permission errors.
  Stream<List<MoveServiceWarning>> setServiceWarningListener() async* {
    yield* MovesdkPlatform.instance.setServiceWarningListener();
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
    yield* MovesdkPlatform.instance.setServiceErrorListener();
  }

  /// Starts scanning for devices that can be registered with the sdk
  /// Scan can be filtered with [filter], default includes only paired devices.
  /// For scanning beaons [uuid] and [manufacturerId] must be specified.
  /// Will stop when stream is closed.
  Stream<List<MoveDevice>> startScanningDevices(
      {List<MoveDeviceFilter> filter = const [MoveDeviceFilter.paired],
      String? uuid,
      int? manufacturerId}) async* {
    yield* MovesdkPlatform.instance
        .startScanningDevices(filter: filter, uuid: uuid, manufacturerId: manufacturerId);
  }

  /// Get a list of devices registered with the sdk to be scanned for during trip.
  Future<List<MoveDevice>> getRegisteredDevices() {
    return MovesdkPlatform.instance.getRegisteredDevices();
  }

  /// Register devices with the sdk to be scanned for during trip.
  /// All will be unregistered on shutdown.
  Future<void> registerDevices(List<MoveDevice> devices) {
    return MovesdkPlatform.instance.registerDevices(devices);
  }

  /// Unregister devices with the sdk to be scanned for during trip
  Future<void> unregisterDevices(List<MoveDevice> devices) {
    return MovesdkPlatform.instance.unregisterDevices(devices);
  }

  /// Device listener fired on device scans during trips.
  Stream<List<MoveScanResult>> setDeviceDiscoveryListener() async* {
    yield* MovesdkPlatform.instance.setDeviceDiscoveryListener();
  }
}
