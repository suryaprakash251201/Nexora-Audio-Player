import 'user_dto.dart';

class AuthResponseDto {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserDto user;

  AuthResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    // Handle nesting: {data: {accessToken, user}} or flat
    Map<String, dynamic> payload = json;
    if (json['data'] is Map<String, dynamic>) {
      payload = json['data'] as Map<String, dynamic>;
    }
    // Tokens may be nested under tokens: {tokens: {accessToken}}
    if (payload['tokens'] is Map) {
      payload = {...payload, ...(payload['tokens'] as Map<String, dynamic>)};
    }

    String token =
        (payload['accessToken'] ??
                payload['token'] ??
                payload['access_token'] ??
                payload['jwt'] ??
                '')
            .toString();
    String? refresh = (payload['refreshToken'] ?? payload['refresh_token'])
        ?.toString();
    int? expires;
    if (payload['expiresIn'] != null) {
      expires = payload['expiresIn'] is int
          ? payload['expiresIn'] as int
          : int.tryParse(payload['expiresIn'].toString());
    }

    Map<String, dynamic> userJson = {};
    if (payload['user'] is Map<String, dynamic>) {
      userJson = payload['user'] as Map<String, dynamic>;
    } else if (payload['profile'] is Map<String, dynamic>) {
      userJson = payload['profile'] as Map<String, dynamic>;
    } else {
      // Fallback: payload itself contains user fields
      userJson = payload;
    }

    return AuthResponseDto(
      accessToken: token,
      refreshToken: refresh,
      expiresIn: expires,
      user: UserDto.fromJson(userJson),
    );
  }
}
