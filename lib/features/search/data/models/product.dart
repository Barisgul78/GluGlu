enum ProductStatus { safe, risky, unknown }

class Product {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  final String? ingredients;
  final String? barkod;
  final ProductStatus status;
  final String category;
  // Anahtarlar Firestore `besin_degerleri` anahtarlarıdır (enerji_kcal, protein, yag...).
  // Yalnızca dolu olanlar bulunur; boşsa ürünün besin bilgisi yoktur.
  final Map<String, String> nutrition;
  final String? kanitCumlesi;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.ingredients,
    this.barkod,
    required this.status,
    required this.category,
    this.nutrition = const {},
    this.kanitCumlesi,
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    ProductStatus parseStatus(String? st) {
      if (st == 'GUVENLI') return ProductStatus.safe;
      if (st == 'RISKLI') return ProductStatus.risky;
      return ProductStatus.unknown;
    }

    return Product(
      id: data['id'] ?? '',
      name: data['urun_adi'] ?? '',
      brand: data['marka'] ?? '',
      imageUrl: data['resim'] ?? '',
      ingredients: data['icindekiler'],
      barkod: data['barkod'],
      status: parseStatus(data['durum']),
      category: data['kategori'] ?? 'Genel',
      nutrition: _parseNutrition(data),
      kanitCumlesi: data['kanit_cumlesi']?.toString(),
    );
  }

  // Eski düz alanlar (kalori/protein/karbonhidrat) yedek okunur; besin_degerleri öncelikli.
  static Map<String, String> _parseNutrition(Map<String, dynamic> data) {
    final result = <String, String>{};

    void put(String key, Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) result[key] = text;
    }

    put('enerji_kcal', data['kalori']);
    put('protein', data['protein']);
    put('karbonhidrat', data['karbonhidrat']);

    final map = data['besin_degerleri'];
    if (map is Map) {
      map.forEach((key, value) => put(key.toString(), value));
    }
    return result;
  }
}
