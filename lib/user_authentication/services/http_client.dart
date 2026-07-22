import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiClient {
  static http.Client createClient() {
    final HttpClient httpClient = HttpClient();

    // Set proxy
    httpClient.findProxy = (Uri uri) {
      return "PROXY 172.16.1.61:8080";
      // OR
      // return "PROXY proxy.company.com:8080";
      // OR
      // return "DIRECT"; // No proxy
    };

    // Ignore SSL certificate (Only for testing)
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    return IOClient(httpClient);
  }
}