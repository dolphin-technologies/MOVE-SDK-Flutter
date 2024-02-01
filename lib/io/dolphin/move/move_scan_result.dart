import 'package:movesdk/io/dolphin/move/move_device.dart';

class MoveScanResult {
  bool isDiscovered;
  MoveDevice device;

  MoveScanResult(this.isDiscovered, this.device);

  static List<MoveScanResult> fromNative(results) {
    List<MoveScanResult> moveResults = [];
    for (var result in results) {
      String name = result["name"];
      String data = result["device"];
      bool isDiscovered = result["isDiscovered"];
      moveResults.add(MoveScanResult(isDiscovered, MoveDevice(name, data)));
    }
    return moveResults;
  }
}
