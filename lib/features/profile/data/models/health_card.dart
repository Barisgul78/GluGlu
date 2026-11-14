import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/string_utils.dart';

// Beslenme ihtiyacı seçenekleri — Firestore'a `key` yazılır, UI'da `label` görünür.
enum HealthNeed {
  colyak('COLYAK', 'Çölyak'),
  glutenHassasiyeti('GLUTEN_HASSASIYETI', 'Gluten hassasiyeti'),
  bugdayAlerjisi('BUGDAY_ALERJISI', 'Buğday alerjisi'),
  diger('DIGER', 'Diğer');

  const HealthNeed(this.key, this.label);

  final String key;
  final String label;

  static HealthNeed? fromKey(String key) {
    for (final need in HealthNeed.values) {
      if (need.key == key) return need;
    }
    return null;
  }
}

// users/{uid}.saglik_karti map'i
class HealthCard {
  const HealthCard({
    required this.adSoyad,
    required this.needs,
    required this.avoided,
    this.crossContact = false,
    this.note = '',
  });

  static const maxNoteLength = 200;

  final String adSoyad;
  final List<HealthNeed> needs;
  final String avoided;
  final bool crossContact;
  final String note;

  // Eksik alanlı eski doküman crash ettirmez; map yoksa "kart yok" = null.
  static HealthCard? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final keys = (data['ihtiyaclar'] as List<dynamic>? ?? const []);
    final needs = keys
        .map((k) => HealthNeed.fromKey('$k'))
        .whereType<HealthNeed>()
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return HealthCard(
      adSoyad: data['ad_soyad'] as String? ?? '',
      needs: needs,
      avoided: data['tuketilemeyenler'] as String? ?? '',
      crossContact: data['capraz_temas'] as bool? ?? false,
      note: data['not'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'ad_soyad': adSoyad,
        'ihtiyaclar': needs.map((n) => n.key).toList(),
        'tuketilemeyenler': avoided,
        'capraz_temas': crossContact,
        'not': note,
        'guncelleme_tarihi': Timestamp.fromDate(DateTime.now()),
      };

  // "Çölyak • Gluten hassasiyeti • Glutensiz beslenme"
  String get needsLine =>
      [...needs.map((n) => n.label), 'Glutensiz beslenme'].join(' • ');

  // Yazılan metin isim tamlaması olabilir ("… içeren ürünler") → tam cümleye çevrilir.
  String get avoidSentence {
    final text = avoided.trim().replaceAll(RegExp(r'[.!\s]+$'), '');
    if (text.isEmpty) return '';
    final capitalized = capitalizeFirst(text);
    return text.toLowerCase().endsWith('tüketemem')
        ? '$capitalized.'
        : '$capitalized tüketemem.';
  }
}
