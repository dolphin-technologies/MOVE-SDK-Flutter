# Flutter Move SDK

Flutter package for MOVE SDK - please see https://docs.movesdk.com/move/ for features and details about the MOVE SDK.

## Installation

Add the Dolphin MOVE SDK package to your flutter app using:
flutter pub add movesdk
or, by adding it as a dependency to your pubspec.yaml file and run:
flutter pub get
See https://docs.flutter.dev/packages-and-plugins/using-packages for further information regarding package use.

```
import 'package:movesdk/movesdk.dart';
```

### Android

The SDK needs to be initialized at the start of the app by calling MoveSdk.init. It is recommended to put this in the Application's onCreate method. This will load the persistent Move SDK state.
```
import io.dolphin.move.MoveSdk

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        val sdk = MoveSdk.init(this)
        ...
    }
    
    ...
}
```

### iOS

Inititalization happens automatically in appDidFinishLaunching.

## Support
Contact info@dolph.in
 
## License

The contents of this repository are licensed under the
[Apache License, version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
