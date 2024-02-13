import 'dart:io';

import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
        case PermissionStatus.permanentlyDenied:
          permissionStatusText = "permanentlyDenied";
          statusColor = Colors.red;
          break;
        case PermissionStatus.provisional:
          permissionStatusText = "provisional";
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 135.0,
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
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                ),
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
