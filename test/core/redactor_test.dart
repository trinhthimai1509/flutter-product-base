import 'package:flutter_project_base/core/logging/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacts sensitive keys recursively, case/format-insensitive', () {
    final redacted = Redactor.redact({
      'email': 'a@b.c',
      'password': 'secret',
      'nested': {
        'access_token': 'abc',
        'Refresh-Token': 'def',
        'list': [
          {'apiKey': 'k', 'name': 'ok'},
        ],
      },
    });
    expect(redacted, {
      'email': 'a@b.c',
      'password': Redactor.placeholder,
      'nested': {
        'access_token': Redactor.placeholder,
        'Refresh-Token': Redactor.placeholder,
        'list': [
          {'apiKey': Redactor.placeholder, 'name': 'ok'},
        ],
      },
    });
  });

  test('redacts authorization header', () {
    final headers = Redactor.redactHeaders({
      'Authorization': 'Bearer xyz',
      'Accept': 'application/json',
    });
    expect(headers['Authorization'], Redactor.placeholder);
    expect(headers['Accept'], 'application/json');
  });
}
