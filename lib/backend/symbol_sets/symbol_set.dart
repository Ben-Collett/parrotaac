import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parrotaac/backend/attribution_data.dart';

abstract class SymbolSet {
  ///should be sorted based on a relavince score, if there is no logical way to determie a relavince score assign the score based on alphabetical order of the labels, though as it stands this is not being done anywhere.
  Future<List<SymbolResult>> search(String toSearch);
}

abstract class SymbolResult {
  Widget get asImageWidget;
  double get relevance;
  String get label;
  String? get originalImageUrl;
  String? get imageUrl;
  String get currentVariant;
  bool get supportsTones;

  Future<AttributionData> get attributionData;

  void changeVariant(dynamic vareint);

  ///returns a file object with the data no garntee on the path, or how long the file will exist, should be copied to a new path to manipulate
  Future<File> get asFile;
}
