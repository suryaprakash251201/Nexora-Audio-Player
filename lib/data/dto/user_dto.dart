import '../../domain/entities/user.dart';

class UserDto {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  UserDto({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory UserDto.fromJson(Map<String, dynamic> j) {
    return UserDto(
      id: (j['id'] ?? j['_id'] ?? j['userId'] ?? '').toString(),
      username: (j['username'] ?? j['name'] ?? j['email'] ?? 'user').toString(),
      email: j['email']?.toString(),
      displayName: (j['displayName'] ?? j['display_name'] ?? j['name'])
          ?.toString(),
      avatarUrl: (j['avatarUrl'] ?? j['avatar'] ?? j['image'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (email != null) 'email': email,
    if (displayName != null) 'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  User toEntity() => User(
    id: id,
    username: username,
    email: email,
    displayName: displayName,
    avatarUrl: avatarUrl,
  );
}
