import 'dart:convert';
import 'package:http/http.dart' as http;

import 'http_client.dart';

class LoadingService {
  static final http.Client client = ApiClient.createClient();

  static const String icmsUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/ntesRestServices/";

  static const String loadingSummaryUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/DataFromICMSToPMSRest/";

  static const String validateTrainLoadUrl =
      "https://parcel.indianrail.gov.in/PMSRestServicesv23/services/PMSStatus/validateTrainLoad/";

  static const String railwayALUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getRailwayAL/";

  static const String wagonMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getWagonMaster/";

  static const String wagtypeALUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getWagTypeAL/";

  static const String plateformMasterUrl =
      "https://parcel.indianrail.gov.in/PMSRestServices/services/PMSStatus/getPlatformMaster/";
  static Future<List<dynamic>> getWagonMaster() async {
    try {
      final response = await client.post(
        Uri.parse(wagonMasterUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          // request parameters if required
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static Future<bool> login(
    String username,
    String password,
    String station,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(wagonMasterUrl),
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
