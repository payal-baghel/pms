import 'dart:convert';
import 'package:http/http.dart' as http;

import 'http_client.dart';

class LoginService {
  static final http.Client client = ApiClient.createClient();
  static const String userloginUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/validateUser/";

  // Credentials of the logged-in user (used by other services like getWagonMaster)
  static String? loggedInUserId;
  static String? loggedInPassword;
  static String? loggedInStation;

  // Session cookie returned by the server on successful login.
  // Some services (e.g. getWagonMaster) require it to return data.
  static String? sessionCookie;

  static Future<bool> login(
    String username,
    String password,
    String station,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(userloginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userid": username,
          "password": password,
          "stncode": station,
          "strapptype": "Test",
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("API Response: ${response.body}");

      // Capture the session cookie from the login response
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        sessionCookie = setCookie.split(';').first.trim();
        print("Session Cookie: $sessionCookie");
      }

      if (response.statusCode == 200) {
        final success = response.body.toLowerCase().contains("true");
        if (success) {
          loggedInUserId = username;
          loggedInPassword = password;
          loggedInStation = station;
        }
        return success;
      } else {
        return false;
      }
    } catch (e) {
      print("API Error: $e");
      return false;
    }
  }
}
