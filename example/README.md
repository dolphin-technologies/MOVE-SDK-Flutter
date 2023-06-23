# Dolphin MOVE SDK Flutter Example
Reference: MOVE SDK [documentation](https://docs.movesdk.com/).

An example for the Dolphin Move SDK Flutter plugin.

## App cycle goes as follows:

On app initialization, the SDK will be initialized automatically and store its persisted state.

#### Toggle Activation switch: ON
- Creates a user for you if no user already exists
- SDK will be in ready state and app will automatically start SDK services using ‘startAutomaticDetection’ API

#### Toggle Activation switch: OFF
- Stops the SDK services using ‘stopAutomaticDetection’ API.
- As the sample app is using the ‘stopAutomaticDetection’ API and not ‘shutdown’, the SDK state will only transit to ready state and not shutdown. Hence, future on toggles will only start SDK services without re-creating a user or re-initializing the SDK.

The SDK activation toggling State is persisted for future initializations.

## To run this project:

1. Request a product API Key by contacting Dolphin MOVE.
2. TODO: insert API key "Bearer <api-key>" (AuthClient.registerUser in auth_api.dart)
3. Launch a device such as the iOS Simulator.
4. Using the terminal, run `flutter run lib/io/dolphin/move/example/main.dart`

## Starting Point:

### SDK Setup:

#### Authorization

After contacting us and getting a  product API key, use it to fetch a MoveAuth from the Move Server. MoveAuth object will be passed to the SDK on initialization and be used by the SDK to authenticate its services.

If the provided MoveAuth was invalid, the SDK will not try to fetch a new auth through the auth expiry listener. Check documentation for details.

The setup is persisted for the SDK to automatically continue when the app is relaunched from the background.

To unregister the user with the SDK use the `shutdown` method.

#### Configuration

MoveConfig allows host apps to configure which of the licensed Move services should be enabled. It could be based on each user preference or set from a remote server. Services which do not have the required permsissions may not run or only collect incomplete data. 

## Support
Contact info@dolph.in
 
## License

The contents of this repository are licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
