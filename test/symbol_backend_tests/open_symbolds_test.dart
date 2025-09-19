import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/backend/server/server_utils.dart' as server;
import 'package:parrotaac/backend/symbol_sets/open_symbol.dart';

void main() async {
  final tokenOverride =
      "temp::2025-09-07:1757268193:59b3f68116a1c0d120b0354a:3c3052b9bb2eaeac6f5db984f549d1bfbc9199bbf1c497b80f1b7f359127078ed570af6e83b910583cf83fea956410ed319cd1b2f4bbf30e59dd771a20d09da3";
  server.accessTokenOverride = tokenOverride;
  test('test search', () async {
    await OpenSymbolSet().search("cat");
  });
}
