import 'package:flutter/material.dart';
import 'package:movesdk_example/core/utils.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';

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
