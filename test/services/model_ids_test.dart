import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weirdchess/services/config_service.dart';

/// Guards against the failure that broke commentary on all platforms in Aug
/// 2026: a shipped default pointed at a model the provider had retired, so
/// every request 404'd upstream and surfaced as "API error: 500".
///
/// These are offline checks — they only assert internal consistency.  Live
/// verification that a model id still exists is done by /api/health.
void main() {
  group('shipped model ids', () {
    test('no provider default is a retired model', () {
      for (final provider in LlmProvider.values) {
        expect(
          kRetiredModels.containsKey(provider.defaultModel),
          isFalse,
          reason:
              '${provider.name} defaults to ${provider.defaultModel}, which is '
              'listed as retired. Update defaultModel to its replacement.',
        );
      }
    });

    test('bundled assets/config.json uses no retired model', () {
      final raw = File('assets/config.json').readAsStringSync();
      final models =
          (jsonDecode(raw) as Map<String, dynamic>)['models'] as Map<String, dynamic>;
      for (final entry in models.entries) {
        expect(
          kRetiredModels.containsKey(entry.value),
          isFalse,
          reason:
              'assets/config.json pins ${entry.key} to ${entry.value}, which is '
              'retired. This file ships inside the app bundle and is the config '
              'used on a fresh install.',
        );
      }
    });

    test('retired ids never map to another retired id', () {
      for (final entry in kRetiredModels.entries) {
        expect(
          kRetiredModels.containsKey(entry.value),
          isFalse,
          reason: '${entry.key} remaps to ${entry.value}, which is also retired.',
        );
      }
    });

    test('resolveRetiredModel upgrades a stale id and passes a live one', () {
      expect(resolveRetiredModel('claude-3-haiku-20240307'),
          equals('claude-haiku-4-5-20251001'));
      expect(resolveRetiredModel('gemini-2.5-flash'), equals('gemini-2.5-flash'));
    });
  });
}
