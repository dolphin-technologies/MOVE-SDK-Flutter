import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';
import 'package:movesdk/movesdk.dart';
import 'package:movesdk_example/core/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/auth_api.dart';

// TODO: Replace with your own API key
String apiKey = "";

class AppModel extends ChangeNotifier {
  final _moveSdkPlugin = MoveSdk();

  MoveState? sdkState;
  MoveAuthState? authState;
  MoveTripState? tripState;
  List<MoveServiceError>? errors;
  List<MoveServiceWarning>? warnings;

  MoveAppConfiguration? config;

  String? userID;

  AppModel() {
    initListeners();
    initSharedPrefs();
  }

  initSharedPrefs() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    config = MoveAppConfiguration.load(sharedPreferences);
    userID = config?.userId;
  }

  initListeners() async {
    _moveSdkPlugin.setSdkStateListener().listen((moveSdkState) {
      sdkState = moveSdkState;
      notifyListeners();
    });

    _moveSdkPlugin.setAuthStateListener().listen((moveAuthState) {
      authState = moveAuthState;
      notifyListeners();
      switch (authState) {
        case MoveAuthState.invalid:
          _moveSdkPlugin.shutdown();
          break;
        default:
          break;
      }
    });

    _moveSdkPlugin.setTripStateListener().listen((moveTripState) {
      tripState = moveTripState;
      notifyListeners();
    });

    _moveSdkPlugin.setServiceErrorListener().listen((moveServiceError) {
      errors = moveServiceError;
      notifyListeners();
    });

    _moveSdkPlugin.setServiceWarningListener().listen((moveServiceWarning) {
      warnings = moveServiceWarning;
      notifyListeners();
    });
  }

  resolveError() {
    _moveSdkPlugin.resolveError();
  }

  toggleAutomaticDetection(BuildContext context, bool value) async {
    if (apiKey == "") {
      Fluttertoast.showToast(
          msg:
              "Missing Api Key! Please replace apiKey in app.dart with your own API key.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      return;
    }

    if (value) {
      if (userID == null) {
        var userID =
            "${DateTime.now().toUtc().millisecondsSinceEpoch}".substring(0, 10);
        this.userID = userID;

        MoveAuth moveAuth = await AuthClient.registerUser(
          context,
          apiKey: apiKey,
          userId: userID,
        );

        var moveConfig = MoveConfig(MoveDetectionService.values);

        _moveSdkPlugin.setup(moveAuth, moveConfig);

        config?.userId = userID;
        var sharedPreferences = await SharedPreferences.getInstance();
        config?.save(sharedPreferences);
      }

      _moveSdkPlugin.startAutomaticDetection();
    } else {
      _moveSdkPlugin.stopAutomaticDetection();
    }
  }
}
