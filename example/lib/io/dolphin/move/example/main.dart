import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movesdk/io/dolphin/move/move_auth_result.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:movesdk/io/dolphin/move/move_auth_state.dart';
import 'package:movesdk/io/dolphin/move/move_detection_service.dart';
import 'package:movesdk/io/dolphin/move/move_service_warning.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:movesdk/io/dolphin/move/move_trip_state.dart';
import 'package:movesdk/movesdk.dart';
import 'package:movesdk_example/io/dolphin/move/example/client/auth_api.dart';
import 'package:movesdk_example/io/dolphin/move/example/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension ListSpaceBetweenExtension on List<Widget> {
  List<Widget> withSpaceBetween({final double? width, final double? height}) =>
      [
        for (int i = 0; i < length; i++) ...[
          if (i > 0) SizedBox(width: width, height: height),
          this[i],
        ],
      ];
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: kDebugMode,
      home: ChangeNotifierProvider(
        create: (context) => AppModel(),
        child: const MyApp(),
      ),
    ),
  );
}

const Color headlineColor = Color(0xFF061230);
const Color textColor = Color(0xFF6D7486);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

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

  showAlert(BuildContext context, String title, String msg) async {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
          },
          child: const Text("Close"),
        ),
      ],
      contentTextStyle: const TextStyle(color: Colors.black),
      titleTextStyle: const TextStyle(color: Colors.black),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  toggleAutomaticDetection(BuildContext context, bool value) async {
    if (value) {
      if (userID == null) {
        var userID =
            "${DateTime.now().toUtc().millisecondsSinceEpoch}".substring(0, 10);
        this.userID = userID;
      }

      var state = await _moveSdkPlugin.getState();
      if (state == MoveState.unknown) {
        try {
          String authCode = await AuthClient.registerAuthCode(userID!);

          var moveConfig = MoveConfig([
            MoveDetectionService.driving,
            MoveDetectionService.drivingBehaviour,
            MoveDetectionService.distractionFreeDriving,
            MoveDetectionService.cycling,
            MoveDetectionService.publicTransport,
            MoveDetectionService.pointsOfInterest
          ]);

          var status = await _moveSdkPlugin.setupWithCode(authCode, moveConfig);
          if (status.status == AuthSetupStatus.success) {
            config?.userId = userID;
            var sharedPreferences = await SharedPreferences.getInstance();
            config?.save(sharedPreferences);
          } else {
            if (context.mounted) {
              showAlert(
                  context, "Error", "${status.status} : ${status.description}");
            }
            return;
          }
        } catch (error) {
          if (context.mounted) {
            showAlert(context, "Error", error.toString());
          }
          return;
        }
      }

      _moveSdkPlugin.startAutomaticDetection();
    } else {
      _moveSdkPlugin.stopAutomaticDetection();
    }
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, app, child) {
        return MaterialApp(
          theme: ThemeData(
            fontFamily: "HelveticaNeue",
            primarySwatch: Colors.blue,
            textTheme: const TextTheme(
                bodyMedium: TextStyle(color: textColor),
                headlineMedium: TextStyle(
                    color: headlineColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 17.0),
                headlineSmall: TextStyle(
                    color: headlineColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0),
                titleLarge: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20.0),
                titleMedium: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17.0),
                titleSmall: TextStyle(
                    color: headlineColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0),
                labelSmall: TextStyle(color: textColor, fontSize: 12.0)),
            appBarTheme: const AppBarTheme(
              color: Color(0xFF071230),
              foregroundColor: Colors.white,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarBrightness: Brightness.dark,
              ),
            ),
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const Text(
                'MOVE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20.0),
              ),
            ),
            body: Column(children: [
              const MoveStateHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Errors",
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                ...(app.errors ?? []).map((e) => Text(
                                    "${e.service.name} - ${e.reasons.map((e) => e.name)}",
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))),
                                Text("Warnings",
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                ...(app.warnings ?? []).map((e) => Text(
                                    "${e.service?.name ?? ""} - ${e.reasons.map((e) => e.name)}",
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold))),
                              ].withSpaceBetween(height: 5.0)),
                        ),
                        const MovePermissionsWidget(),
                        const MoveStateFooter(),
                      ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class MoveStateHeader extends StatefulWidget {
  const MoveStateHeader({super.key});

  @override
  State<MoveStateHeader> createState() => _MoveStateHeader();
}

class _MoveStateHeader extends State<MoveStateHeader> {
  static final activeColors = [
    const Color(0xFFBEE969),
    const Color(0xFF5A9132),
  ];

  static final inactiveColors = [
    const Color(0xFFF3505E),
    const Color(0xFFA00510),
  ];

  static const recordingText = "RECORDING";
  static const notRecordingText = "NOT RECORDING";

  bool switchState = false;
  List<Color> backgroundColors = inactiveColors;
  String recordingState = notRecordingText;
  AppModel? appModel;
  MoveState sdkState = MoveState.unknown;
  String userID = "-";

  changeSwitchState(bool value) {
    setState(() {
      switchState = value;
      if (value) {
        backgroundColors = activeColors;
        recordingState = recordingText;
      } else {
        backgroundColors = inactiveColors;
        recordingState = notRecordingText;
      }
    });
  }

  modelListener() {
    AppModel? model = appModel;
    if (model == null) {
      return;
    }

    if (model.sdkState != sdkState) {
      sdkState = model.sdkState ?? MoveState.unknown;
      changeSwitchState(model.sdkState == MoveState.running);
    }

    if (model.userID != userID) {
      userID = model.userID ?? "-";
    }
  }

  setModel(AppModel model) {
    if (appModel != null) {
      return;
    }
    appModel = model;
    appModel?.addListener(modelListener);
  }

  @override
  Widget build(BuildContext context) {
    setModel(Provider.of<AppModel>(context, listen: false));
    return Column(children: [
      AnimatedContainer(
        height: 167.715,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundColors,
          ),
        ),
        duration: const Duration(milliseconds: 200),
        // Provide an optional curve to make the animation feel smoother.
        curve: Curves.fastOutSlowIn,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text("CURRENT STATE",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: Container(
              height: 100.0,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 10.0, 10.0, 0.0),
                        child: Row(children: [
                          Text(recordingState,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const Spacer(),
                          Switch(
                            value: switchState,
                            activeColor: Colors.green,
                            onChanged: (bool value) {
                              appModel?.toggleAutomaticDetection(
                                  context, value);
                            },
                          )
                        ])),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 0,
                      endIndent: 0,
                      color: Colors.white,
                    ),
                    Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
                        child: Text("Your contract id: $userID"))
                  ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class MoveStateFooter extends StatefulWidget {
  const MoveStateFooter({super.key});

  @override
  State<MoveStateFooter> createState() => _MoveStateFooter();
}

class _MoveStateFooter extends State<MoveStateFooter> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(builder: (context, app, child) {
      return Container(
        padding: const EdgeInsets.only(top: 16.0),
        alignment: Alignment.center,
        height: 100.0,
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFF3F3F3)),
        child: Column(
            children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("SDK STATE: ", style: Theme.of(context).textTheme.titleSmall),
            Text("${app.sdkState}",
                style: Theme.of(context).textTheme.labelSmall)
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("SDK TRIP STATE: ",
                style: Theme.of(context).textTheme.titleSmall),
            Text("${app.tripState}",
                style: Theme.of(context).textTheme.labelSmall)
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("SDK AUTH STATE: ",
                style: Theme.of(context).textTheme.titleSmall),
            Text("${app.authState}",
                style: Theme.of(context).textTheme.labelSmall)
          ]),
        ].withSpaceBetween(height: 5.0)),
      );
    });
  }
}

class MovePermissionsWidget extends StatefulWidget {
  const MovePermissionsWidget({super.key});

  @override
  State<MovePermissionsWidget> createState() => _MovePermissionsWidget();
}

class _MovePermissionsWidget extends State<MovePermissionsWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("PERMISSIONS",
                style: Theme.of(context).textTheme.headlineMedium),
            const Text(
                "MOVE needs the following permissions to record your activities. Please check each one and grant them."),
            const MovePermissionWidget(
                title: "LOCATIONS",
                description:
                    "MOVE needs the location permission to track user trips and activities.",
                permission: Permission.location),
            if (Platform.isIOS)
              const MovePermissionWidget(
                  title: "MOTION",
                  description:
                      "MOVE needs the motion permission in order to record walking activities. Please grant access to your fitness & motion data.",
                  permission: Permission.sensors),
            if (Platform.isAndroid) ...[
              const MovePermissionWidget(
                  title: "BACKGROUND LOCATION",
                  description:
                      "MOVE should be able to access the location in the background.",
                  permission: Permission.locationAlways),
              const MovePermissionWidget(
                  title: "MOTION",
                  description:
                      "MOVE needs the motion permission in order to record walking activities. Please grant access to your fitness & motion data.",
                  permission: Permission.activityRecognition),
              const MovePermissionWidget(
                  title: "PHONE",
                  description:
                      "We use this to detect whether you are using the phone while driving.",
                  permission: Permission.phone),
              const MovePermissionWidget(
                  title: "OVERLAY",
                  description:
                      "We use this to detect whether you are using the phone while driving.",
                  permission: Permission.systemAlertWindow),
              const MovePermissionWidget(
                  title: "BATTERY",
                  description:
                      "We use this to detect driving also in the background.",
                  permission: Permission.ignoreBatteryOptimizations),
              const MovePermissionWidget(
                  title: "BLUETOOTH SCAN",
                  description: "We use this to look for Bluetooth devices",
                  permission: Permission.bluetoothScan),
              const MovePermissionWidget(
                  title: "BLUETOOTH CONNECT",
                  description:
                      "We use this to connect with already paired Bluetooth devices",
                  permission: Permission.bluetoothConnect),
            ],
          ].withSpaceBetween(height: 10.0)),
    );
  }
}

class MovePermissionWidget extends StatefulWidget {
  final String title;
  final String description;
  final Permission permission;

  const MovePermissionWidget({
    super.key,
    required this.title,
    required this.description,
    required this.permission,
  });

  @override
  State<MovePermissionWidget> createState() => _MovePermissionWidget();
}

class _MovePermissionWidget extends State<MovePermissionWidget> {
  String permissionStatusText = "Unknown";
  Color statusColor = Colors.red;

  _MovePermissionWidget();

  @override
  initState() {
    super.initState();
    updatePermissionState();
  }

  updatePermissionState() async {
    PermissionStatus status = await widget.permission.status;
    updatePermissionStatus(status);
  }

  updatePermissionStatus(PermissionStatus status) {
    setState(() {
      switch (status) {
        case PermissionStatus.denied:
          permissionStatusText = "denied";
          statusColor = Colors.red;
          break;
        case PermissionStatus.granted:
          permissionStatusText = "granted";
          statusColor = Colors.green;
          break;
        case PermissionStatus.restricted:
          permissionStatusText = "restricted";
          statusColor = Colors.orange;
          break;
        case PermissionStatus.limited:
          permissionStatusText = "limited";
          statusColor = Colors.yellow;
          break;
        case PermissionStatus.provisional:
          permissionStatusText = "provisional";
          statusColor = Colors.yellow;
          break;
        case PermissionStatus.permanentlyDenied:
          permissionStatusText = "permanentlyDenied";
          statusColor = Colors.red;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.all(Radius.circular(15.0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 10.0, 0.0),
          child: Row(
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              MaterialButton(
                onPressed: () async {
                  var appModel = Provider.of<AppModel>(context, listen: false);
                  PermissionStatus status = await widget.permission.request();
                  updatePermissionStatus(status);
                  if (status != PermissionStatus.granted) {
                    openAppSettings();
                  } else {
                    appModel.resolveError();
                  }
                },
                color: statusColor,
                child: Text(permissionStatusText),
              )
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          indent: 0,
          endIndent: 0,
          color: Colors.white,
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
            child: Text(widget.description))
      ]),
    );
  }
}
