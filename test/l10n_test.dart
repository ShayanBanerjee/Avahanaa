import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the translations against the way they actually rot.
///
/// Nobody deletes a Kannada string on purpose. What happens is that an English
/// string is added for a new feature, the ARB beside it is not touched, and the
/// generated getter quietly falls back to English. The screen then reads as
/// half-translated, which is worse than not offering the language at all —
/// it looks like the app gave up halfway.
void main() {
  Map<String, dynamic> readArb(String name) {
    final file = File('lib/l10n/$name');
    expect(file.existsSync(), isTrue, reason: '$name is missing');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Message keys only — `@@locale` and the `@key` metadata blocks are not
  /// translatable strings.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  late Map<String, dynamic> en;
  late Map<String, dynamic> kn;

  setUp(() {
    en = readArb('app_en.arb');
    kn = readArb('app_kn.arb');
  });

  test('every English string has a Kannada one', () {
    expect(
      messageKeys(en).difference(messageKeys(kn)),
      isEmpty,
      reason: 'untranslated keys will silently render in English',
    );
  });

  test('Kannada carries nothing English does not', () {
    expect(
      messageKeys(kn).difference(messageKeys(en)),
      isEmpty,
      reason: 'a key with no English source is dead weight',
    );
  });

  test('placeholders match on both sides', () {
    // `{count}` written as `{कount}` or dropped entirely throws at runtime
    // rather than degrading, and only on the locale nobody tests in.
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in messageKeys(en)) {
      final source = en[key] as String;
      final target = kn[key] as String;
      expect(
        placeholder.allMatches(target).map((m) => m.group(1)).toSet(),
        placeholder.allMatches(source).map((m) => m.group(1)).toSet(),
        reason: 'placeholders differ for "$key"',
      );
    }
  });

  test('nothing is left as an untranslated copy of the English', () {
    // A key translated by pasting the English is the failure this whole file
    // exists to catch. Brand names and bare placeholders are the honest
    // exceptions.
    const allowed = <String>{};
    final untranslated = <String>[];

    for (final key in messageKeys(en)) {
      if (allowed.contains(key)) continue;
      final source = (en[key] as String).trim();
      final target = (kn[key] as String).trim();
      if (source.isEmpty || target != source) continue;
      // Identical is fine when there is nothing to translate.
      if (RegExp(r'^[\W\d\s]*$').hasMatch(source)) continue;
      untranslated.add(key);
    }

    expect(untranslated, isEmpty, reason: 'still in English: $untranslated');
  });

  test('Kannada strings are actually in Kannada script', () {
    // Catches a placeholder-only or transliterated entry. Strings that are
    // deliberately a brand name are listed rather than guessed at.
    const brandOnly = <String>{};
    final kannada = RegExp(r'[ಀ-೿]');

    for (final key in messageKeys(kn)) {
      if (brandOnly.contains(key)) continue;
      final value = kn[key] as String;
      if (RegExp(r'^[\W\d\s]*$').hasMatch(value)) continue;
      expect(
        kannada.hasMatch(value),
        isTrue,
        reason: '"$key" carries no Kannada characters: "$value"',
      );
    }
  });
}
