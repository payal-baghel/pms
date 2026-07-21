import 'dart:convert';
import 'package:http/http.dart' as http;

import 'http_client.dart';

class ApiService {
  static final http.Client client = ApiClient.createClient();
  static const String url =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/validateUser";

  static Future<bool> login(
    String username,
    String password,
    String station,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(url),
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

      if (response.statusCode == 200) {
        return response.body.toLowerCase().contains("true");
      } else {
        return false;
      }
    } catch (e) {
      print("API Error: $e");
      return false;
    }
  }
}
