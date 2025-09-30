// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInResponse _$SignInResponseFromJson(Map<String, dynamic> json) =>
    SignInResponse(
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as String,
      email: json['email'] as String,
      localId: json['localId'] as String,
      registered: json['registered'] as bool,
    );

Map<String, dynamic> _$SignInResponseToJson(SignInResponse instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
      'email': instance.email,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'localId': instance.localId,
      'registered': instance.registered,
    };

CreateAccountResponse _$CreateAccountResponseFromJson(
  Map<String, dynamic> json,
) => CreateAccountResponse(
  idToken: json['idToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: json['expiresIn'] as String,
  email: json['email'] as String,
  localId: json['localId'] as String,
);

Map<String, dynamic> _$CreateAccountResponseToJson(
  CreateAccountResponse instance,
) => <String, dynamic>{
  'idToken': instance.idToken,
  'email': instance.email,
  'refreshToken': instance.refreshToken,
  'expiresIn': instance.expiresIn,
  'localId': instance.localId,
};

RefreshIdResponse _$RefreshIdResponseFromJson(Map<String, dynamic> json) =>
    RefreshIdResponse(
      expiresIn: json['expires_in'] as String,
      tokenType: json['token_type'] as String,
      refreshToken: json['refresh_token'] as String,
      idToken: json['id_token'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
    );

Map<String, dynamic> _$RefreshIdResponseToJson(RefreshIdResponse instance) =>
    <String, dynamic>{
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
      'refresh_token': instance.refreshToken,
      'id_token': instance.idToken,
      'user_id': instance.userId,
      'project_id': instance.projectId,
    };
