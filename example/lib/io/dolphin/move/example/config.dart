import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoveAppConfiguration {
  String? projectId;
  String? userId;

  bool? allowMockLocations;
  bool? keepActive;
  bool? keepInForeground;

  List<MoveDetectionService>? moveDetectionServices;

  MoveAppConfiguration({
    this.userId,
    this.moveDetectionServices,
    // android
    this.allowMockLocations,
    this.keepActive,
    this.keepInForeground,
  });

  MoveAppConfiguration.load(SharedPreferences prefs) {
    userId = prefs.getString("userId");
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
    prefs.setString("userId", userId ?? "");
    prefs.setBool("allowMockLocations", allowMockLocations == true);
    prefs.setBool("keepActive", keepActive == true);
    prefs.setBool("keepInForeground", keepInForeground == true);

    prefs.setStringList("moveDetectionServices",
        moveDetectionServices?.map((e) => e.name).toList() ?? []);
  }
}
