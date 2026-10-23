---
name: glufree-new-feature
description: GluFree'ye uçtan uca özellik ekleme akışı — spec, katman sırası, rota bağlama, istatistik entegrasyonu, doğrulama ve teslim. Yeni özellik, yeni ekran veya birden çok dosyaya dokunan her işte İLK adım olarak kullan. Yarım bırakılan rota bağlantısı, eksik durum ekranı ve onaysız kapsam genişlemesini önler.
---

# GluFree Yeni Özellik Akışı

Bu repoda bir özellik "çalışan widget" değil, **spec → katmanlar → rota → doğrulama → teslim** zincirinin tamamıdır. Zincirin bir halkasını atlayan iş yarımdır. Adımları sırayla uygula; her adımın çıktısı bir sonrakinin girdisi.

## Adım 0 — Kapsam kapısı

Başlamadan cevapla:

1. **Bu iş §1'deki (CLAUDE.new.md) bilinçli kararlardan biriyle çelişiyor mu?** (barkod, ekranları Riverpod'a taşıma, koyu tema, server-side arama, client'tan katalog yazma...) → Çelişiyorsa DUR, kararı hatırlat, açık onay iste.
2. **Firestore'da olmayan veri gerekiyor mu?** (örn. mekan koordinatı, ürün fiyatı) → DUR, kullanıcıya sor — veri konsoldan girilir, sen üretemezsin.
3. **Kaç dosyaya dokunacak?** 3+ dosya veya davranış değişikliği → **plan mode zorunlu.** Onaysız kod yok.

## Adım 1 — Spec (orta/büyük işlerde)

`docs/superpowers/specs/YYYY-MM-DD-<konu>-design.md` oluştur. Şablon (repodaki `2026-07-02-favori-makaleler-design.md` birebir örnek):

```markdown
# <Özellik adı>

## Amaç
Kullanıcı gözünden tek paragraf: ne yapabilecek, şu an ne eksik.

## Veri Modeli
Firestore'a dokunuyorsa: hangi koleksiyon/alan, mevcut desenle ilişkisi.
(glufree-firestore skill'ini burada aç — alan adları oradan.)

## Servis Katmanı
Hangi servise hangi statik metotlar; hangi mevcut metodun deseni kopyalanıyor.

## Ekran(lar)
Ekran başına: hangi mevcut ekranın iskeleti, hangi widget'lar yeniden kullanılıyor.
(glufree-ui-kit skill'i buranın kaynağı.)

## Kapsam Dışı
Neye DOKUNULMAYACAĞI — madde madde. Bu bölüm boşsa spec eksiktir.

## Doğrulama
flutter analyze + adım adım manuel smoke listesi (eylem → beklenen sonuç).
```

Spec'i sun, **onay bekle**, sonra koda geç.

## Adım 2 — Katman sırası (her zaman içten dışa)

Sıra: **model → servis → widget → ekran → rota**. Ters gitme; rota olmadan ekran test edilemez ama servis olmadan ekran hiç yazılamaz.

### 2a. Model (`features/<f>/data/models/`)
- Immutable, `const` constructor, `fromFirestore` factory.
- Her alan toleranslı: `data['alan'] ?? varsayılan`. Firestore alan adları **glufree-firestore** skill'indeki tablodan — uydurma.
- Dart alanları İngilizce camelCase olabilir (mevcut desen: `urun_adi` → `name`).

### 2b. Servis (`features/<f>/data/services/`)
```dart
class YeniService {
  YeniService._();
  static Future<X> metod(...) async { ... }
}
```
- Firestore SADECE burada; UI importu yok; koleksiyon adı `app_constants.dart` sabitinden.
- `AuthService.currentUserId == null` ele alınır (kullanıcıya-özel veri ise).
- En yakın mevcut servisi bul, desenini kopyala: sayfalama → `VenuesService`, array-favori → `FavoritesService`, sayaç/transaction → `StatsService`, auth akışı → `AuthService`.

### 2c. Ortak widget (`features/<f>/presentation/widgets/`)
Aynı feature'da 2+ ekranda kullanılacak parça buraya; 2+ feature kullanacaksa `core/widgets/`. Tek ekranlık parça ekranın private metodu kalır (`_buildX`).

### 2d. Ekran (`features/<f>/presentation/screens/`)
- `StatefulWidget` + `setState`. Riverpod'a taşıma yok.
- Zorunlu üçlü: loading / error (Türkçe) / empty (Türkçe). İskelet ve tarifler **glufree-ui-kit** skill'inden.
- `mounted` kontrolleri + tüm controller'lar dispose.

### 2e. Rota (`core/routing/app_router.dart`)
- `GoRoute` yalnızca burada tanımlanır.
- Tam ekran (sekme çubuğu ÜSTÜNDE) → `parentNavigatorKey: rootNavigatorKey`. **Bu satır bu akışın en çok unutulan adımı — iki kez kontrol et.**
- Nesne taşıma: `context.push('/yol', extra: nesne)` + builder'da `state.extra as Tip` cast.
- Yeni sekme ekleme ayrı ve büyük iştir (`_branchPaths` + `MainShell` destinations senkron değişmeli) — spec'te açıkça yoksa yapma.

## Adım 3 — İstatistik entegrasyonu (varsa)

Kullanıcının bir şeyi "keşfetmesi/okuması/araması" sayılacaksa `StatsService` çağrısı ekle (mevcut prefix'ler: `aranan_urun`, `kesfedilen_mekan`, `tiklanan_urun`, `okunan_makale`). Yeni prefix = yeni Firestore alanları → Adım 0.2 kapısından geçir (kullanıcıya sor).

## Adım 4 — Doğrulama

1. `flutter analyze` → **0 issue.** Çıktıyı raporla; temiz değilse iş bitmemiştir.
2. Smoke listesini spec'ten al, her adımı "eylem → beklenen" formatında son haliyle yaz. Cihazda koşan kullanıcıdır — liste onun için, çalıştırılabilir netlikte olmalı:
   - Mutlu yol (özelliğin ana akışı uçtan uca)
   - Boş durum (hiç veri yokken)
   - Girişsiz durum (`currentUserId == null` — özellik kullanıcıya-özelse)
   - Kalıcılık (uygulama yeniden açılınca veri duruyor mu — Firestore'a yazan işlerde)
   - Geri navigasyon (push edilen ekrandan `pop` ile dönüş)
3. Kapsam denetimi: diff'i spec'in "Kapsam Dışı" bölümüyle karşılaştır. Dokunulmayacak denilen dosyada değişiklik varsa ya geri al ya gerekçesiyle açıkça bildir.

## Adım 5 — Teslim

Rapor şunları içerir (sırayla):
1. Ne eklendi — kullanıcı gözünden bir cümle.
2. Dosya listesi: yeni / değişen, tek satır açıklamayla.
3. Plandan/spec'ten sapmalar (yoksa "sapma yok").
4. `flutter analyze` sonucu.
5. Manuel smoke listesi.
6. Commit önerisi: Türkçe, kısa, tek mantıksal iş (`makale favorileri eklendi` tarzı). Kullanıcı istemeden commit atma.

## Kırmızı çizgiler (bu akış sırasında asla)

- Onaysız: pubspec'e paket ekleme, `firestore.rules` değiştirme, redirect/`main.dart` init değişikliği, tema paleti dokunuşu.
- "Hazır buradayken" refactor'u — spec dışı iyileştirme gördüysen yapma, teslim raporunda öneri olarak listele.
- Var olmayan test altyapısına atıf ("testler geçiyor" yok; kapı analyze + smoke).
