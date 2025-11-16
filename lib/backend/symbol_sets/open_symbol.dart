import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:parrotaac/backend/attribution_data.dart';
import 'package:parrotaac/backend/server/server_utils.dart';
import 'package:parrotaac/backend/simple_logger.dart';
import 'package:parrotaac/backend/symbol_sets/symbol_set.dart';
import 'package:parrotaac/extensions/http_extensions.dart';
import 'package:parrotaac/extensions/null_extensions.dart';
import 'package:parrotaac/utils.dart';

class OpenSymbolSet extends SymbolSet {
  @override
  Future<List<SymbolResult>> search(String toSearch) async {
    if (toSearch.trim().isEmpty) {
      return Future.value([]);
    }
    final uri = Uri.https('www.opensymbols.org', '/api/v2/symbols', {
      'access_token': await temporaryOpenSymbolToken,
      'q': toSearch,
      'locale': 'en',
      'safe': '1',
    });

    try {
      final file = await DefaultCacheManager().getSingleFile(
        uri.toString(),
        key: uri.toString(),
      );

      final contents = await file.readAsString();
      final data = json.decode(contents);

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(OpenSymbolResult.fromJson)
            .where((result) => true)
            .toList();
      }
    } on HttpException catch (e) {
      // Handle network/cache failures
      SimpleLogger().logError("HTTP/Cache error: $e");
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      SimpleLogger().logError("JSON parse error: $e");
    } catch (e) {
      SimpleLogger().logError("Unexpected error: $e");
    }

    return List<SymbolResult>.empty();
  }
}

class OpenSymbolResult extends SymbolResult {
  @override
  String get imageUrl => getUpdatedUrl(_currentVariant, originalImageUrl);
  @override
  final String originalImageUrl;
  @override
  double get relevance => json["relevance"];

  @override
  final bool supportsTones;

  String _currentVariant = "default";
  @override
  String get currentVariant => _currentVariant;

  @override
  String get label => json["name"];

  String get _license => json["license"];

  final Map<String, dynamic> json;

  Map<String, dynamic> encode() {
    return {"variant": _currentVariant, "json": json};
  }

  static OpenSymbolResult decode(Map<String, dynamic> encoded) {
    return OpenSymbolResult.fromJson(encoded["json"])
      .._currentVariant = encoded["variant"];
  }

  @override
  Future<AttributionData> get attributionData async {
    final String title = json['name'] ?? 'untitiled';

    final String author = json['author'] ?? 'unknown';
    final String? authorUrl = await _urlIfIsValid(json['author_url']);

    final String license = json['license'];
    final String? licenseUrl = await _urlIfIsValid(json['license_url']);

    return AttributionData([
      AttributionProperty(label: 'title', value: title, url: imageUrl),
      AttributionProperty(label: 'author', value: author, url: authorUrl),
      AttributionProperty(label: 'license', value: license, url: licenseUrl),
    ]);
  }

  Future<String?> _urlIfIsValid(String? url) {
    if (url == null) {
      return Future.value(null);
    }
    return http
        .head(Uri.parse(url))
        .then((val) => val.isSuccessfulResponse ? url : null);
  }

  //if we ever need to go commercial
  bool get supportCommercialUse => !_license.contains("NC");

  OpenSymbolResult.fromJson(this.json)
    : originalImageUrl = json["image_url"],
      supportsTones = json["skins"].ifMissingDefaultTo(false);

  @override
  Widget get asImageWidget => imageFromUrl(imageUrl);

  @override
  String toString() =>
      """
image_url=$imageUrl
original_image_url=$originalImageUrl
relavince=$relevance
label=$label
    """;

  @override
  Future<File> get asFile => DefaultCacheManager().getSingleFile(imageUrl);

  @override
  void changeVariant(dynamic variant) {
    if (variant is String) {
      _currentVariant = variant;
    } else {
      SimpleLogger().logError("invalid change variant request");
    }
  }

  static const Map<String, String?> skinTones = {
    "default": null,
    'light': '1f3fb',
    'medium-light': '1f3fc',
    'medium': '1f3fd',
    'medium-dark': '1f3fe',
    'dark': '1f3ff',
  };

  static String getUpdatedUrl(String toneName, String originalImageUrl) {
    if (toneName == 'default') {
      return originalImageUrl;
    }
    if (originalImageUrl.contains('varianted-skin')) {
      // Replace the 'varianted-skin' placeholder with correct variant name
      return originalImageUrl.replaceAll('varianted-skin', 'variant-$toneName');
    }

    String hexCode = skinTones[toneName]!;

    // Match "-varXXXXUNI" pattern
    final regExp = RegExp(r'-var[a-zA-Z0-9]+UNI');
    if (regExp.hasMatch(originalImageUrl)) {
      return originalImageUrl.replaceAllMapped(regExp, (match) => '-$hexCode');
    }

    // Fallback: try inserting before extension
    final uri = Uri.parse(originalImageUrl);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      final prefix = path.substring(0, lastDot);
      final ext = path.substring(lastDot);
      final newPath = '$prefix-variant-$toneName$ext';

      return uri.replace(path: newPath).toString();
    }

    // No extension? Just append
    return '$originalImageUrl-variant-$toneName';
  }
}
