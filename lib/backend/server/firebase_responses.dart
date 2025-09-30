import 'package:json_annotation/json_annotation.dart';
part 'firebase_responses.g.dart';

abstract class LoginResponse {
  String get idToken;
  String get email;
  String get refreshToken;
  String get expiresIn;
  String get localId;

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class SignInResponse extends LoginResponse {
  @override
  final String idToken;
  @override
  final String email;
  @override
  final String refreshToken;
  @override
  final String expiresIn;
  @override
  final String localId;
  final bool registered;

  SignInResponse({
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.email,
    required this.localId,
    required this.registered,
  });
  factory SignInResponse.fromJson(Map<String, dynamic> json) =>
      _$SignInResponseFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SignInResponseToJson(this);
}

@JsonSerializable()
class CreateAccountResponse extends LoginResponse {
  @override
  final String idToken;
  @override
  final String email;
  @override
  final String refreshToken;
  @override
  final String expiresIn;
  @override
  final String localId;
  CreateAccountResponse({
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.email,
    required this.localId,
  });
  factory CreateAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateAccountResponseFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CreateAccountResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshIdResponse {
  final String expiresIn;
  final String tokenType;
  final String refreshToken;
  final String idToken;
  final String userId;
  final String projectId;

  RefreshIdResponse({
    required this.expiresIn,
    required this.tokenType,
    required this.refreshToken,
    required this.idToken,
    required this.userId,
    required this.projectId,
  });

  factory RefreshIdResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshIdResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshIdResponseToJson(this);
}
