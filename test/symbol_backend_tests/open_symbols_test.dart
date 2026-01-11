import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/backend/network/custom_cache_manager.dart';
import 'package:parrotaac/backend/symbol_sets/open_symbol.dart';
import 'package:parrotaac/backend/symbol_sets/symbol_set.dart';
import 'package:parrotaac/backend/symbol_sets/token_provider.dart';

import '../data/open_symbol_sample_results.dart';

import 'package:file/file.dart';

final fs = MemoryFileSystem();

class OpenSymbolCacheManagerMock implements CustomCacheManager {
  @override
  Future<File> getSingleFile(String url, {String? key}) async {
    if (url.contains('cat')) {
      return fs.file('cat.txt')..writeAsStringSync(catSearchResult);
    } else if (url.contains('run')) {
      return fs.file('run.txt')..writeAsStringSync(runSearchResult);
    }

    return fs.file('empty.txt')..writeAsStringSync('');
  }
}

class EmptyTokenProvider implements TokenProvider {
  @override
  Future<String> generateToken() async {
    return "empty";
  }
}

void main() async {
  test('test cat search', () async {
    List<SymbolResult> results = await OpenSymbolSet().search(
      "cat",
      tokenProvider: EmptyTokenProvider(),
      cacheManager: OpenSymbolCacheManagerMock(),
    );
    expect(results.length, 1);
    expect(
      results[0].imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/arasaac/cat.png",
    );
  });

  test('test run search', () async {
    List<SymbolResult> results = await OpenSymbolSet().search(
      "run",
      tokenProvider: EmptyTokenProvider(),
      cacheManager: OpenSymbolCacheManagerMock(),
    );
    expect(results.length, 2);
    expect(results[1].supportsTones, true);
  });

  test('change tone', () {
    final result = OpenSymbolResult.fromJson(toneSupportingJson);
    expect(result.supportsTones, true);

    const defaultUrl =
        "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-varxxxUNI-200d-2640-fe0f.svg";
    result.changeVariant("default");
    expect(result.imageUrl, defaultUrl);

    result.changeVariant("light");
    expect(
      result.imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-1f3fb-200d-2640-fe0f.svg",
    );

    result.changeVariant("medium-light");
    expect(
      result.imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-1f3fc-200d-2640-fe0f.svg",
    );

    result.changeVariant("default");
    expect(result.imageUrl, defaultUrl);

    result.changeVariant("medium");
    expect(
      result.imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-1f3fd-200d-2640-fe0f.svg",
    );

    result.changeVariant("medium-dark");
    expect(
      result.imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-1f3fe-200d-2640-fe0f.svg",
    );

    result.changeVariant("dark");
    expect(
      result.imageUrl,
      "https://d18vdu4p71yql0.cloudfront.net/libraries/twemoji/1f3c3-1f3ff-200d-2640-fe0f.svg",
    );
  });

  //WARNING AI TEST BELOW THIS POINT
  group('OpenSymbolResult minimal parsing', () {
    test('creates minimal OpenSymbolResult from JSON', () {
      final json = {
        'name': 'wave',
        'image_url': 'https://example.com/wave.png',
        'relevance': 0.9,
        'license': 'CC-BY',
        'skins': false,
      };

      final result = OpenSymbolResult.fromJson(json);

      expect(result.label, equals('wave'));
      expect(result.originalImageUrl, equals('https://example.com/wave.png'));
      expect(result.imageUrl, equals('https://example.com/wave.png'));
      expect(result.relevance, equals(0.9));
      expect(result.supportsTones, isFalse);
      expect(result.currentVariant, equals('default'));
    });
  });
  group('OpenSymbolResult variant URL fallbacks', () {
    final variants = OpenSymbolResult.skinTones.keys;

    test('updates URLs correctly for all variants', () {
      final baseUrls = {
        'variantedSkin': 'https://example.com/emoji-varianted-skin.png',
        'unicodeVar': 'https://example.com/emoji-var1F44BUNI.png',
        'extensionFallback': 'https://example.com/emoji.png',
      };

      for (final variant in variants) {
        for (final entry in baseUrls.entries) {
          final updated = OpenSymbolResult.getUpdatedUrl(variant, entry.value);

          if (variant == 'default') {
            expect(
              updated,
              equals(entry.value),
              reason: 'default variant should not modify URL (${entry.key})',
            );
          } else {
            expect(
              updated,
              isNot(equals(entry.value)),
              reason: 'non-default variant should modify URL (${entry.key})',
            );

            expect(
              updated.contains(variant) ||
                  updated.contains(OpenSymbolResult.skinTones[variant] ?? ''),
              isTrue,
              reason:
                  'updated URL should contain variant or hex (${entry.key})',
            );
          }
        }
      }
    });
  });
}
