class AppUser {
  const AppUser({required this.id, required this.email, this.name});

  final String id;
  final String email;

  /// From `users.name` — nullable because it's optional at signup (only
  /// set if the client passes one on first login).
  final String? name;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }

  /// Prefers the real `name`; falls back to deriving one from the email's
  /// local part when the user never set one.
  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;

    final localPart = email.split('@').first;
    if (localPart.isEmpty) return email;
    return localPart[0].toUpperCase() + localPart.substring(1);
  }

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return trimmed[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
