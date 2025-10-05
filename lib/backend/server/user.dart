import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:parrotaac/backend/server/firebase_responses.dart';
import 'package:parrotaac/extensions/http_extensions.dart';

import 'firebase_constants.dart';

const _emailKey = 'email';
const _refreshTokenKey = "refresh_token";
const _idTokenKey = "id_token";
const _apiExpirationTimeKey = "api_expiration";

class User {
  final _UserData _userData;
  Future<http.Response> makeRequest(
    Future<Response> Function(String) request,
  ) async {
    if (DateTime.now().isAfter(_userData.idExpirationTime)) {
      await _refreshIdToken();
    }

    Response response = await request(_userData.idToken);
    if (response.isSuccessfulResponse) {
      return response;
    } else {
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json.containsKey("message")) {
        if (json["message"] == "TOKEN_EXPIRED" ||
            json["message"] == "INVALID_ID_TOKEN") {
          await _refreshIdToken();
        }
        response = await request(_userData.idToken);
      }
      return response;
    }
  }

  Future<void> _refreshIdToken() async {
    final url = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _userData.refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final RefreshIdResponse data = RefreshIdResponse.fromJson(
        json.decode(response.body),
      );

      await Future.wait([
        _updateExpirationTime(data.expiresIn),
        _updateRefreshToken(data.refreshToken),
        _updateIdToken(data.idToken),
      ]);
    } else {
      throw Exception(
        'Failed to refresh token: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> _updateRefreshToken(String refreshToken) {
    return FlutterSecureStorage().write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  Future<void> _updateIdToken(String idToken) {
    _userData.idToken = idToken;
    return FlutterSecureStorage().write(key: _idTokenKey, value: idToken);
  }

  Future<void> _updateExpirationTime(String timeTillExpirationInSeconds) {
    final expirationTime = _calcExpirationTime(
      int.parse(timeTillExpirationInSeconds),
    );

    _userData.idExpirationTime = expirationTime;
    return FlutterSecureStorage().write(
      key: _apiExpirationTimeKey,
      value: expirationTime.toString(),
    );
  }

  static DateTime _calcExpirationTime(int seconds) {
    return DateTime.now().add(Duration(seconds: seconds));
  }

  User._(_UserData data) : _userData = data;

  Future<void> updateStoredUser() async {
    await Future.wait([
      FlutterSecureStorage().write(
        key: _refreshTokenKey,
        value: _userData.refreshToken,
      ),
      FlutterSecureStorage().write(
        key: _apiExpirationTimeKey,
        value: _userData.idExpirationTime.toString(),
      ),
      FlutterSecureStorage().write(key: _idTokenKey, value: _userData.idToken),
      FlutterSecureStorage().write(key: _emailKey, value: _userData.email),
    ]);
  }

  Future<void> logout() {
    return Future.wait([
      FlutterSecureStorage().delete(key: _refreshTokenKey),
      FlutterSecureStorage().delete(key: _idTokenKey),
      FlutterSecureStorage().delete(key: _apiExpirationTimeKey),
      FlutterSecureStorage().delete(key: _emailKey),
    ]);
  }

  User.fromLogin(LoginResponse response)
    : this._(
        _UserData(
          email: response.email,
          refreshToken: response.refreshToken,
          idToken: response.idToken,
          idExpirationTime: _calcExpirationTime(int.parse(response.expiresIn)),
        ),
      );

  static Future<User?> get storedUser async {
    final data = await _UserData.fromStorage;
    if (data == null) {
      return null;
    }
    return User._(data);
  }

  @override
  String toString() {
    return _userData.toString();
  }
}

class _UserData {
  final String email;
  String refreshToken;
  String idToken;
  DateTime idExpirationTime;

  _UserData({
    required this.email,
    required this.refreshToken,
    required this.idToken,
    required this.idExpirationTime,
  });

  static Future<_UserData?> get fromStorage async {
    const store = FlutterSecureStorage();
    List<String?> results = await Future.wait([
      store.read(key: _emailKey),
      store.read(key: _idTokenKey),
      store.read(key: _refreshTokenKey),
      store.read(key: _apiExpirationTimeKey),
    ]);

    if (results.contains(null)) {
      return null;
    }

    return _UserData(
      email: results[0]!,
      idToken: results[1]!,
      refreshToken: results[2]!,
      idExpirationTime: DateTime.tryParse(results[3]!) ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return "email=$email\nrefreshToken=$refreshToken\nidToken=$idToken\nidExpirationTime=$idExpirationTime";
  }
}
