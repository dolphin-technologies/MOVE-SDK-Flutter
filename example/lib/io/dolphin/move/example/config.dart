import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoveAppConfiguration {
  String? projectId;
  String? userId;
  String? accessToken;
  String? refreshToken;

  bool? allowMockLocations;
  bool? keepActive;
  bool? keepInForeground;

  List<MoveDetectionService>? moveDetectionServices;

  MoveAppConfiguration({
    this.projectId,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.moveDetectionServices,
    // android
    this.allowMockLocations,
    this.keepActive,
    this.keepInForeground,
  });

  MoveAppConfiguration.load(SharedPreferences prefs) {
    projectId = prefs.getString("projectId");
    userId = prefs.getString("userId");
    accessToken = prefs.getString("accessToken");
    refreshToken = prefs.getString("refreshToken");
    allowMockLocations = prefs.getBool("allowMockLocations");
    keepActive = prefs.getBool("keepActive");
    keepInForeground = prefs.getBool("keepInForeground");

    var services = prefs.getStringList("moveDetectionServices");
    List<MoveDetectionService> storedMoveDetectionServices = [];
    if (services != null) {
      for (var service in services) {
        var detectionService = MoveDetectionService.values
            .where((element) =>
                element.name.toLowerCase() == service.toLowerCase())
            .first;
        storedMoveDetectionServices.add(detectionService);
      }
    }
    moveDetectionServices = storedMoveDetectionServices;
  }

  void save(SharedPreferences prefs) {
    prefs.setString("projectId", projectId ?? "");
    prefs.setString("userId", userId ?? "");
    prefs.setString("accessToken", accessToken ?? "");
    prefs.setString("refreshToken", refreshToken ?? "");
    prefs.setBool("allowMockLocations", allowMockLocations == true);
    prefs.setBool("keepActive", keepActive == true);
    prefs.setBool("keepInForeground", keepInForeground == true);

    prefs.setStringList("moveDetectionServices",
        moveDetectionServices?.map((e) => e.name).toList() ?? []);
  }
}
