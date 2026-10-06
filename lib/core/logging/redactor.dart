/// Removes sensitive values before anything is logged.
abstract final class Redactor {
  static const placeholder = '***';

  /// Keys (case-insensitive, `-`/`_` ignored) whose values are never logged.
  static const _sensitiveKeys = {
    'password',
    'newpassword',
    'oldpassword',
    'passwordconfirmation',
    'token',
    'accesstoken',
    'refreshtoken',
    'idtoken',
    'authorization',
    'cookie',
    'setcookie',
    'secret',
    'clientsecret',
    'apikey',
    'xapikey',
    'otp',
    'pin',
    'cardnumber',
    'cvv',
    'ssn',
  };

  static bool isSensitiveKey(String key) =>
      _sensitiveKeys.contains(key.toLowerCase().replaceAll(RegExp('[-_]'), ''));

  /// Recursively redacts maps and lists. Other values are returned as is.
  static Object? redact(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: isSensitiveKey(entry.key.toString())
              ? placeholder
              : redact(entry.value),
      };
    }
    if (value is List) return value.map(redact).toList();
    return value;
  }

  static Map<String, Object?> redactHeaders(Map<String, dynamic> headers) => {
    for (final entry in headers.entries)
      entry.key: isSensitiveKey(entry.key) ? placeholder : entry.value,
  };
}
