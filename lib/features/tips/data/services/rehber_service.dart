import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/tip.dart';

class RehberService {
  RehberService._();

  // Tek alan eşitliği: bileşik indeks gerekmez. Sıralama Dart'ta (orderBy indeks ister).
  static Future<List<Tip>> fetchByTopic(String topicId) async {
    final snap = await FirebaseFirestore.instance
        .collection(kRehberBilgileriCollection)
        .where('konu_id', isEqualTo: topicId)
        .limit(50)
        .get();

    final docs = snap.docs.toList()
      ..sort((a, b) {
        final sa = (a.data()['sira'] as num?) ?? 0;
        final sb = (b.data()['sira'] as num?) ?? 0;
        return sa.compareTo(sb);
      });
    return docs.map((d) => Tip.fromFirestore(d.id, d.data())).toList();
  }
}
