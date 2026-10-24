import 'package:flutter/services.dart';

/// Flutter port of the Cordova `cordova-plugin-scanner` (ScannerPlugin).
///
/// The native Android side (MainActivity) listens for the broadcast
///   action : android.decode.scan_result
///   extra  : code_data
/// and pushes each scan string through this EventChannel.
///
/// Usage:
///   final sub = ScannerBroadcast.scans.listen((raw) { ... });
///   ...
///   sub.cancel();
class ScannerBroadcast {
  ScannerBroadcast._();

  static const EventChannel _channel = EventChannel('cordova/scanner');

  /// Stream of raw barcode strings sent by the hardware scanner.
  static Stream<String> get scans =>
      _channel.receiveBroadcastStream().map((event) => event.toString());
}
