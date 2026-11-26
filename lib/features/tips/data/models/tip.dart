import 'package:cloud_firestore/cloud_firestore.dart';

class TipSection {
  final String heading;
  final String body;

  const TipSection({required this.heading, required this.body});

  factory TipSection.fromMap(Map<String, dynamic> data) => TipSection(
        heading: data['baslik'] ?? '',
        body: data['metin'] ?? '',
      );
}

class Tip {
  final String id;
  final String category;
  final String imageAsset;
  final String title;
  final String summary;
  final List<TipSection> sections;
  final DateTime date;
  // Rehber konusuna bağlı kayıtlarda dolu; Günün Bilgisi kayıtlarında null
  final String? topicId;

  const Tip({
    required this.id,
    required this.category,
    required this.imageAsset,
    required this.title,
    required this.summary,
    required this.sections,
    required this.date,
    this.topicId,
  });

  factory Tip.fromFirestore(String id, Map<String, dynamic> data) {
    final rawSections = data['bolumler'];
    final sections = rawSections is List
        ? rawSections
            .whereType<Map>()
            .map((m) => TipSection.fromMap(Map<String, dynamic>.from(m)))
            .toList()
        : <TipSection>[];
    final timestamp = data['guncelleme_tarihi'];

    return Tip(
      id: id,
      category: data['kategori'] ?? '',
      imageAsset: 'assets/images/ipucu.jpg',
      title: data['baslik'] ?? '',
      summary: data['ozet'] ?? '',
      sections: sections,
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      topicId: data['konu_id'],
    );
  }
}
