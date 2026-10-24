import 'dart:convert';

/// Result of the "loading guidance" API (getActualLoadDtls).
///
/// The service is called with
/// {"DETAIL":"{\"TRAINNO\":\"12566\",\"STNCODE\":\"NDLS\",\"VCLTYPE\":\"FCRSLR\",\"SCHLD_DT\":\"21/Sep/2026 12:45\",\"LOAD_DT\":\"21/Sep/2026 12:45\",\"APPTYPE\":\"Online\"}"}
/// and answers with the actual load details of that train (one object per
/// PWB/PRR). The exact wrapper is not documented, so every plausible shape is
/// accepted and the raw body is kept for the console log.
class ActualLoadDtlsResult {
  /// Request completed and the body was readable JSON.
  final bool ok;

  /// Untouched response body - printed to the console for field mapping.
  final String rawBody;

  /// Server side description / error text, when present.
  final String message;

  /// Actual load rows found in the response.
  final List<Map<String, dynamic>> rows;

  const ActualLoadDtlsResult({
    required this.ok,
    required this.rawBody,
    this.message = "",
    this.rows = const [],
  });

  bool get hasRows => rows.isNotEmpty;

  static ActualLoadDtlsResult fromBody(String body) {
    List<Map<String, dynamic>> found = [];
    var message = "";

    try {
      final decoded = _tryDecode(body);

      if (decoded is List) {
        found = _mapList(decoded);
      } else if (decoded is Map) {
        for (final key in [
          "data",
          "list",
          "rows",
          "result",
          "records",
          "ACTUALLOAD",
          "ACTUAL_LOAD",
          "ACTUAL_LOADDTLS",
          "LOADDTLS",
          "LOADDTLSLIST",
          "PWBLIST",
          "PWB_LIST",
          "table",
          "Table",
        ]) {
          final v = decoded[key];
          if (v is List) {
            found = _mapList(v);
            break;
          }
        }
        // A single row object, or a map of row objects.
        if (found.isEmpty) {
          final values = decoded.values.whereType<Map>().toList();
          if (values.isNotEmpty) {
            found = values
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }

        for (final key in [
          "message",
          "Message",
          "MESSAGE",
          "decription",
          "Decription",
          "description",
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
      return ActualLoadDtlsResult(
        ok: false,
        rawBody: body,
        message: "Unable to read response: $e",
      );
    }

    return ActualLoadDtlsResult(
      ok: true,
      rawBody: body,
      message: message,
      rows: found,
    );
  }

  static List<Map<String, dynamic>> _mapList(List<dynamic> list) => list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

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
