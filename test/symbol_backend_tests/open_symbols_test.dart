import 'package:flutter_test/flutter_test.dart';
import 'package:parrotaac/backend/server/server_utils.dart' as server;
import 'package:parrotaac/backend/symbol_sets/open_symbol.dart';
import 'package:parrotaac/backend/symbol_sets/symbol_set.dart';

class SymbolSetMock extends SymbolSet {
  @override
  Future<List<SymbolResult>> search(String toSearch) async {
    if (toSearch == "cat") {
      return 
    } else if (toSearch == "dog") {
      return 
    } else {
      return [];
    }
  }
}

void main() async {
  test('test search', () async {
    await Sym().search("cat");
  });
}
