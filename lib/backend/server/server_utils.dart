_AccessToken? _currentToken;
String? accessTokenOverride;
Future<String> get temporaryOpenSymbolToken async {
  if (accessTokenOverride != null) {
    return Future.value(accessTokenOverride);
  }

  bool needsNewToken = _currentToken?.isExpired ?? true;

  if (needsNewToken) {
    _currentToken = await _requestToken();
  }
  return _currentToken!.token;
}

Future<_AccessToken> _requestToken() {
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
