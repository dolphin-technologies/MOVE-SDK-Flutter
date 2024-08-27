import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthClient {
  /// See https://docs.movesdk.com/move-platform/backend/example-requests
  static const apiKey = "<insert API key>";

  static Future<String> registerAuthCode(String userId) async {
    final query = {'userId': userId};

    var response = await http.get(
      Uri.https('sdk.dolph.in', '/v20/user/authcode', query),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      var authCode = data["authCode"].toString();
      return authCode;
    } else {
      throw Exception('Failed to register user');
    }
  }
}
