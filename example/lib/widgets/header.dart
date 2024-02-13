import 'package:flutter/material.dart';
import 'package:movesdk/io/dolphin/move/move_state.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';

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
