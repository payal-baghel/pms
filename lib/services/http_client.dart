import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiClient {
  static http.Client createClient() {
    final HttpClient httpClient = HttpClient();

    // Set proxy
    httpClient.findProxy = (Uri uri) {
      return "DIRECT"; // No proxy - works outside office network
    };

    // Ignore SSL certificate (Only for testing)
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }
}