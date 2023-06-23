import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movesdk/io/dolphin/move/move_auth.dart';
import 'package:movesdk/movesdk.dart';

class AuthClient {
  static Future<MoveAuth> registerUser(String userId) async {
    final movesdkPlugin = MoveSdk();

    // See https://docs.movesdk.com/move-platform/backend/example-requests
    var apiKey = "<insert API key>";
    var response = await http.post(
      Uri.parse('https://sdk.dolph.in/v20/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(
        <String, String>{
          'userId': userId,
          // put your own device identifier here, e.g. appId
          'installationId': DateTime.now().millisecondsSinceEpoch.toString(),
          'qualifier': await movesdkPlugin.getDeviceQualifier()
        },
      ),
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var userId = data["userId"];
      var projectId = data["projectId"].toString();
      var accessToken = data["accessToken"];
      var refreshToken = data["refreshToken"];
      var moveAuth = MoveAuth(projectId, userId, accessToken, refreshToken);
      return moveAuth;
    } else {
      throw Exception('Failed to register user');
    }
  }
}
