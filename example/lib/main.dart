import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';

import 'core/utils.dart';
import 'core/constants.dart';
import 'models/app.dart';
import 'widgets/footer.dart';
import 'widgets/header.dart';
import 'widgets/permissions.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
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
                                ...(app.errors ?? [])
                                    .map((e) => Text(
                                        "${e.service.name} - ${e.reasons.map((e) => e.name)}",
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)))
                                    .toList(),
                                Text("Warnings",
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                ...(app.warnings ?? [])
                                    .map((e) => Text(
                                        "${e.service?.name ?? ""} - ${e.reasons.map((e) => e.name)}",
                                        style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold)))
                                    .toList(),
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
