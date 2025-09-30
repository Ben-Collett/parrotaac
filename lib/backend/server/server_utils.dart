import 'package:parrotaac/backend/server/login_utils.dart';

_AccessToken? _currentToken;
String? accessTokenOverride;

Future<void> initializeServer() {
  return restoreUser();
}

Future<String> get temporaryOpenSymbolToken async {
  if (accessTokenOverride != null) {
    return Future.value(accessTokenOverride);
  }

  bool needsNewToken = _currentToken?.isExpired ?? true;

  if (needsNewToken) {
    _currentToken = await _requestOpenSymbolToken();
  }
  return _currentToken!.token;
}

Future<_AccessToken> _requestOpenSymbolToken() {
  //TODO:
  throw UnimplementedError();
}

class _AccessToken {
  final String token;
  final DateTime expirationTime;
  bool get isExpired {
    return expirationTime.isBefore(DateTime.now());
  }

  _AccessToken(this.token, this.expirationTime);
}
