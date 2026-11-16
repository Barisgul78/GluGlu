import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../search/data/models/product.dart';

class FavoritesService {
  FavoritesService._();

  static const _field = 'urun_idleri';
  static const _articleField = 'makale_idleri';

  static Future<bool> isProductFavorite(String productId) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return false;
    final doc = await FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId).get();
    if (!doc.exists) return false;
    final List ids = doc.data()?[_field] ?? [];
    return ids.contains(productId);
  }

  static Future<void> toggleProductFavorite(String productId, {required bool isFavorite}) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId);
    if (isFavorite) {
      await docRef.update({_field: FieldValue.arrayRemove([productId])});
    } else {
      await docRef.set({_field: FieldValue.arrayUnion([productId])}, SetOptions(merge: true));
    }
  }

  static Future<void> addProductFavorite(String productId) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    await FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId).set(
      {_field: FieldValue.arrayUnion([productId])},
      SetOptions(merge: true),
    );
  }

  static Stream<DocumentSnapshot> favoritesStream(String userId) =>
      FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId).snapshots();

  static Future<bool> isArticleFavorite(String tipId) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return false;
    final doc = await FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId).get();
    if (!doc.exists) return false;
    final List ids = doc.data()?[_articleField] ?? [];
    return ids.contains(tipId);
  }

  static Future<void> toggleArticleFavorite(String tipId, {required bool isFavorite}) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance.collection(kFavorilerCollection).doc(userId);
    if (isFavorite) {
      await docRef.update({_articleField: FieldValue.arrayRemove([tipId])});
    } else {
      await docRef.set({_articleField: FieldValue.arrayUnion([tipId])}, SetOptions(merge: true));
    }
  }

  // collectionGroup('marka_urunleri') üzerinde where('id') için indeks yok
  // (sorgu failed-precondition verir); arama gibi hepsi çekilip Dart'ta
  // filtrelenir. Sonuç, favori listesinin (ids) sırasındadır.
  static Future<List<Product>> fetchProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snap =
        await FirebaseFirestore.instance.collectionGroup('marka_urunleri').get();
    final byId = <String, Product>{};
    for (final d in snap.docs) {
      final product = Product.fromFirestore(d.data());
      byId[product.id] = product;
    }
    return ids.map((id) => byId[id]).whereType<Product>().toList();
  }
}
