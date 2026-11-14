String initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return parts[0][0].toUpperCase();
}

// Türkçe ilk harf büyütme: i → İ, ı → I (toUpperCase bunu yapmaz).
String capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  final first = switch (s[0]) {
    'i' => 'İ',
    'ı' => 'I',
    final c => c.toUpperCase(),
  };
  return first + s.substring(1);
}
