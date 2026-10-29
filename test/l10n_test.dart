import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

final _placeholder = RegExp(r'\{(\w+)\}');

void main() {
  final template = _arb('en');

  for (final language in ['vi', 'ja']) {
    test('$language translates every message with the same placeholders', () {
      final arb = _arb(language);
      expect(_messageKeys(arb), _messageKeys(template));
      for (final key in _messageKeys(template)) {
        Set<String> names(Map<String, dynamic> a) =>
            _placeholder.allMatches(a[key] as String).map((m) => m[1]!).toSet();
        expect(names(arb), names(template), reason: '$language: $key');
      }
    });
  }
}
