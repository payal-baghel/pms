import 'dart:convert';

/// Result of the searchPwbLoad service.
///
/// The exact response shape of the service is not documented yet, so this
/// model keeps the raw body plus whatever rows could be located. That way the
/// UI can already show a count / error while the field mapping is confirmed.
class PwbLoadSearchResult {
  /// Request completed and the body was readable JSON.
  final bool ok;

  /// Untouched response body - printed to the console for field mapping.
  final String rawBody;

  /// Server side description / error text, when present.
  final String message;

  /// Rows located in the response (empty when the shape is unknown).
  final List<Map<String, dynamic>> rows;

  const PwbLoadSearchResult({
    required this.ok,
    required this.rawBody,
    this.message = "",
    this.rows = const [],
  });

  bool get hasRows => rows.isNotEmpty;

  /// Best-effort scan: the response can be a bare list, or hold the list under
  /// any of the usual wrapper keys.
  static PwbLoadSearchResult fromBody(String body) {
    List<Map<String, dynamic>> found = [];
    var message = "";

    try {
      final decoded = _tryDecode(body);

      if (decoded is List) {
        found = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (decoded is Map) {
        for (final key in [
          "data",
          "list",
          "rows",
          "result",
          "records",
          "PWBLIST",
          "PWB_LIST",
          "LOADLIST",
          "table",
          "Table",
        ]) {
          final v = decoded[key];
          if (v is List) {
            found = v
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            break;
          }
        }

        for (final key in [
          "message",
          "Message",
          "MESSAGE",
          "decription",
          "Decription",
          "errorMessage",
          "ERROR",
        ]) {
          final v = decoded[key];
          if (v != null && v.toString().trim().isNotEmpty) {
            message = v.toString().trim();
            break;
          }
        }
      }
    } catch (e) {
      return PwbLoadSearchResult(
        ok: false,
        rawBody: body,
        message: "Unable to read response: $e",
      );
    }

    return PwbLoadSearchResult(
      ok: true,
      rawBody: body,
      message: message,
      rows: found,
    );
  }

  /// The detail field is frequently a JSON string, so unwrap it when needed.
  static dynamic _tryDecode(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      // fall through - it may be wrapped in a quoted JSON string
    }
    final inner = trimmed.replaceAll('"', '');
    return jsonDecode(inner);
  }
}
