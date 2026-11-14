import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/health_card.dart';

// Kullanıcı profil verisi (users/{userId}) okuma/yazma
class ProfileService {
  static final _users = FirebaseFirestore.instance.collection(kUsersCollection);

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String userId) =>
      _users.doc(userId).snapshots();

  // Tek seferlik okuma — realtime dinleyici gerekmeyen yerlerde (örn. form doldurma) kullanılır.
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) =>
      _users.doc(userId).get();

  static Future<void> setDiagnosisDate(String userId, DateTime date) =>
      _users.doc(userId).set(
        {'tani_tarihi': Timestamp.fromDate(date)},
        SetOptions(merge: true),
      );

  // Okuma: userStream/getUser → `saglik_karti` map'i (HealthCard.fromMap).
  static Future<void> saveHealthCard(String userId, HealthCard card) =>
      _users.doc(userId).set(
        {'saglik_karti': card.toMap()},
        SetOptions(merge: true),
      );

  // İletişim/konum alanları opsiyonel: null verilen alan dokümandan silinir.
  static Future<void> updateContact(
    String userId, {
    String? telefon,
    String? sehir,
  }) =>
      _users.doc(userId).set(
        {
          'telefon': telefon ?? FieldValue.delete(),
          'sehir': sehir ?? FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
}
