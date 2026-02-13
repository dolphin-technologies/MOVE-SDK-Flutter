import 'dart:io';

import 'package:collection/collection.dart';

/// Reason for SDK health warning.
enum MoveHealthReason {
  batteryLevel,
  cpuUsage,
  diskUsage,
  internetUsage,
  memoryUsage,
  newVersion,
  unimplementedListeners,
}

/// Convert from snake case.
MoveHealthReason? mapHealthReason(String kotlinEnum) {
  final mapping = {
    "BATTERY_LEVEL": MoveHealthReason.batteryLevel,
    "CPU_USAGE": MoveHealthReason.cpuUsage,
    "DISK_USAGE": MoveHealthReason.diskUsage,
    "INTERNET_USAGE": MoveHealthReason.internetUsage,
    "MEMORY_USAGE": MoveHealthReason.memoryUsage,
    "NEW_VERSION": MoveHealthReason.newVersion,
    "UNIMPLEMENTED_LISTENERS": MoveHealthReason.unimplementedListeners,
  };

  return mapping[kotlinEnum];
}

/// SDK Health issue item. Callback will push health items if there is an issue the developer needs to look into.
class MoveHealthItem {
  MoveHealthReason reason;
  String description;
  MoveHealthItem(this.reason, this.description);

  /// Convert SDK health [items] from native dict.
  static List<MoveHealthItem> fromNative(items) {
    List<MoveHealthItem> healthItems = [];
    for (var item in items) {
      if (Platform.isAndroid) {
        MoveHealthReason? reason = mapHealthReason(item["reason"]);
        if (reason != null) {
          healthItems.add(MoveHealthItem(reason, item["description"]));
        }
      } else {
        String r = item["reason"];
        MoveHealthReason? reason = MoveHealthReason.values.firstWhereOrNull(
          (element) => element.name.toLowerCase() == r.toLowerCase(),
        );
        if (reason != null) {
          String description = item["description"];
          healthItems.add(MoveHealthItem(reason, description));
        }
      }
    }
    return healthItems;
  }
}
