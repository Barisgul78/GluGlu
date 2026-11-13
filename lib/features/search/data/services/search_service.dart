import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class SearchService {
  SearchService._();

  // Modelin eksik `kategori` varsayılanı; gerçek kategori sayılmaz.
  static const _defaultCategory = 'Genel';

  // Urun adi/marka/kategori uzerinde case-insensitive client-side arama.
  // Firestore'da urun_adi karisik/buyuk harfle kayitli oldugundan
  // (ornek: "NUSTIL Besin Mayasi 100g"), server-side prefix range
  // sorgusu calismiyor - veri kucuk oldugu icin (~80 urun) tumunu
  // cekip Dart tarafinda filtrelemek yeterli. Kategori filtresi de ayni
  // sebeple Dart'ta: collectionGroup where('kategori') indeks ister.
  static Future<List<Product>> searchByName(String query,
      {String? category}) async {
    final q = query.trim().toLowerCase();
    final cat = category?.trim();
    final hasCategory = cat != null && cat.isNotEmpty;
    if (q.isEmpty && !hasCategory) return [];
    final all = await _fetchAll();
    return all.where((p) {
      if (hasCategory && p.category.trim() != cat) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  // Kategori cipleri: urunlerdeki `kategori` degerleri, urun sayisina gore
  // azalan, esitse alfabetik. Bos ve varsayilan ('Genel') kategoriler cip olmaz.
  static Future<List<String>> fetchCategories() async {
    final all = await _fetchAll();
    final counts = <String, int>{};
    for (final p in all) {
      final c = p.category.trim();
      if (c.isEmpty || c == _defaultCategory) continue;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return names;
  }

  // Arama boskeen gosterilen sinirli urun listesi (or. Populer Urunler).
  static Future<List<Product>> fetchFeatured({int limit = 5}) async {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('marka_urunleri')
        .limit(limit)
        .get();
    return snap.docs.map((d) => Product.fromFirestore(d.data())).toList();
  }

  static Future<List<Product>> _fetchAll() async {
    final snap =
        await FirebaseFirestore.instance.collectionGroup('marka_urunleri').get();
    return snap.docs.map((d) => Product.fromFirestore(d.data())).toList();
  }
}
