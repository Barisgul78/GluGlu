String initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  // Ardışık boşluk boş parça üretir; parts[1][0] RangeError atmasın diye ayıklanır.
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
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
