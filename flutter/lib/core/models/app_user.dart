class AppUser {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(id: json['id'] as String, email: json['email'] as String);
  }

  /// The backend has no display-name column on `users` — see
  /// docs/API_GAPS.md. Derived client-side from the email's local part
  /// until the schema grows a `name` field.
  String get displayName {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) return email;
    return localPart[0].toUpperCase() + localPart.substring(1);
  }

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return name[0].toUpperCase();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
