import 'package:parrotaac/backend/server/server_utils.dart';

mixin TokenProvider {
  Future<String> generateToken();
}

class OpenSymbolAccessTokenProvider implements TokenProvider {
  @override
  Future<String> generateToken() => temporaryOpenSymbolToken;
}
