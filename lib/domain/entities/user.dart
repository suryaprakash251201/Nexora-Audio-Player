class User {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  String get name => displayName?.isNotEmpty == true ? displayName! : username;
}
