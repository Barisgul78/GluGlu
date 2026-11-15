---
name: glufree-ui-kit
description: GluFree ev stili UI tarifleri — ekran iskeleti, kart, badge, boş/yükleme/hata durumları, snackbar, buton, tipografi ve renk kuralları. Yeni ekran, kart veya herhangi bir görünür widget üreten HER işte koda başlamadan önce kullan. "Doğru görünen ama ev stiline uymayan" UI üretimini önler.
---

# GluFree UI Kit

Bu uygulamanın görünümü birkaç tekrar eden tariften oluşur. Yeni UI üretirken **tarif uydurma** — buradaki iskeleti kopyala, içeriği değiştir. Amaç: yeni ekranın, mevcut beş sekmeden ayırt edilememesi.

## 0. Token kuralları (istisnasız)

- **Renk:** yalnızca `lib/core/theme/app_colors.dart` k-sabitleri. `Color(0xFF...)` ve `Colors.*` yasak — kabul edilen istisnalar: `Colors.white`, `Colors.transparent`.
- **Font:** tüm metin `GoogleFonts.manrope(...)` (bundle'lı, çevrimdışı çalışır). Başlık/gövde ayrımı ağırlıktan gelir:
  - **Başlık** — ekran başlığı, kart başlığı, buton metni, rakamlar: `FontWeight.bold` / `w700` (bazen `w600`/`w800`).
  - **Gövde** — açıklama, alt satır, boş durum metni, hint: genelde `FontWeight.w500`.
- **Ölçüler:** `AppSizes` sabitleri (`AppSizes.md`, `AppSizes.radiusLg`...). Mevcut kodda `AppSizes.sm + 4` gibi küçük aritmetik kabul; çıplak magic number (örn. `padding: EdgeInsets.all(13)`) yazma.
- **Metin:** kullanıcıya görünen her string Türkçe. Uzun metinde `maxLines` + `TextOverflow.ellipsis`.
- **Görsel:** Firestore `resim` alanı URL veya asset adı olabilir → network görsel her zaman `SafeNetworkImage` (`core/widgets/safe_network_image.dart`), çıplak `Image.network` yasak.

## 1. Ekran iskeleti

Sekme ekranı (Favoriler deseni):

```dart
Scaffold(
  backgroundColor: kBackground,
  body: SafeArea(
    child: Column(
      children: [
        _buildHeader(),          // bkz. §2 header tarifi
        // ...içerik
        Expanded(child: _buildList()),
      ],
    ),
  ),
)
```

Kaydırmalı içerikli ekran (Home deseni): `CustomScrollView` + `SliverAppBar(floating: true, snap: true, backgroundColor: kBackground, surfaceTintColor: Colors.transparent, elevation: 0)` + `SliverToBoxAdapter` içinde `Padding(horizontal: AppSizes.screenPaddingH)`.

Form ekranı (EditProfile deseni): `SafeArea` → `Column` → header + `Expanded(child: SingleChildScrollView(...))` — klavye açılınca taşma olmaz.

## 2. Header (sekme ekranlarının üst çubuğu)

Sol: 36-38px daire avatar (`kPrimary` zemin, `initials(...)` — `core/utils/string_utils.dart`; misafirse `initials(null)` → "?"). Orta: ekran adı `plusJakartaSans` bold 18-20. Sağ: 36-38px daire ikon kutusu (`kSurfaceContainerHigh` zemin veya `kOutlineVariant` border).
Birebir örnek: `favorites_screen.dart` `_buildHeader()`.

## 3. Kart tarifleri

### 3a. Liste satırı kartı (favoriler/arama sonucu — en sık kullanılan)

```dart
Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: kSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kOutlineVariant),
  ),
  child: Row(children: [
    // sol: 72x72 görsel, radius 12, ClipRRect + SafeNetworkImage
    // (badge gerekiyorsa Stack + Positioned(top:4, left:4))
    // orta: Expanded(Column(crossAxisAlignment: start)):
    //   üst satır: marka/yazar UPPERCASE, manrope 10px w700 letterSpacing .8, kOnSurfaceVariant
    //   başlık: manrope bold 15, maxLines 1, ellipsis, kOnSurface
    //   alt satır: manrope 12 w500 kOnSurfaceVariant (kategori/tarih)
    // sağ: aksiyon ikonu (kSecondary, 20-22px) veya chevron (kOutlineVariant)
  ]),
)
```

Birebir örnekler: `favorites_screen.dart` `_buildProductCard` / `_buildArticleCard`.

### 3b. Gölgeli beyaz kart (Home deseni — border yerine gölge)

```dart
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
  boxShadow: [BoxShadow(
    color: kOnSurface.withValues(alpha: 0.05),   // 0.04–0.08 aralığı
    blurRadius: 8,                                // 8–16
    offset: const Offset(0, 2),                   // (0,2)–(0,4)
  )],
)
```

Not: `withOpacity` değil `withValues(alpha: ...)` — lint bunu ister.

### 3c. İkon kutusu (kart içi 40x40 pastel kare)

`Container(width: 40, height: 40, decoration: BoxDecoration(color: kPastelGreen/Blue/Orange/Pink..., borderRadius: BorderRadius.circular(AppSizes.radiusSm + 2)), child: Icon(..., color: kOnSurfaceVariant, size: 20))`.
Listelerde renk rotasyonu: `renkler[index % renkler.length]` (bkz. `home_screen.dart` `_venueIconColors`).

## 4. Badge'ler

- **Ürün durumu:** hazır widget `ProductStatusBadge` (`search/presentation/widgets/`). Kendi durum badge'ini yazma; satır içi varyant gerekiyorsa `favorites_screen.dart` `_statusBadge` renk eşlemesini kullan: safe → `kPrimaryFixed`/`kPrimary` "Glutensiz", risky → `kErrorContainer`/`kOnErrorContainer` "Riskli", unknown → `kSurfaceContainerHigh`/`kOnSurfaceVariant` "Bilinmiyor".
- **Kategori:** hazır widget `CategoryBadge` (`tips/presentation/widgets/`), padding/fontSize parametreli.
- Görsel üstü badge yerleşimi: `Stack` + `Positioned(top: 4, left: 4)`.

## 5. Durum ekranları (üçü de zorunlu)

**Loading:** `Center(child: CircularProgressIndicator(color: kPrimary))`. Kart içi küçük varyant: 20x20 + `strokeWidth: 2`.

**Empty — kısa (liste içi):** ortalanmış tek satır, `manrope`, `kOnSurfaceVariant`, 14, w500. Örn: `'Henüz favori ürün eklemediniz.'`

**Empty — açıklamalı (tam sekme):** ikon (`kOutlineVariant`, ~52px) + bold başlık (`manrope` bold 16) + yönlendirici açıklama (`manrope` w500 13, `height: 1.5`), hepsi `Center` + `Column(mainAxisSize: min)`. Birebir örnek: `favorites_screen.dart` `_buildVenuesList`.

**Error:** kullanıcı diliyle Türkçe mesaj (+ mümkünse "Tekrar dene" aksiyonu). Teknik hata metni (`e.toString()`) kullanıcıya gösterilmez; `debugPrint` ile loglanır. Auth hataları `FirebaseErrorMapper.map(code)` üzerinden.

**Giriş gerekli:** `'Favorilerinizi görmek için\ngiriş yapmanız gerekiyor.'` deseni — `currentUserId == null` olan her kullanıcıya-özel içerikte.

## 6. Geri bildirim

- Hata: `showErrorSnackBar(context, mesaj)`; bilgi: `showInfoSnackBar(context, mesaj)` (`core/utils/snackbars.dart`). Elle `SnackBar` kurma (eski kodda kalanlar var; yeni kod util kullanır).
- Butonlar: `AppButton` (loading parametreli dolu buton) / `AppOutlinedButton` (`core/widgets/custom_button.dart`). Async submit'te `loading: _saving` bağla — çift tıklamayı buton kendisi engeller.
- Bölüm başlığı + "Tümü →" linki: `home_screen.dart` `_buildSectionHeader` tarifi (başlık `manrope` bold, link `manrope` w600 `kPrimary`).

## 7. Ekran davranış kuralları

- `initState`'te yükleme başlat; her `await` sonrası `if (!mounted) return;`; `finally` içinde `if (mounted) setState(...)`.
- Oluşturulan her controller/focus node/timer `dispose()`'da kapatılır.
- Debounce'lu arama: 500ms `Timer` + `_searchRequestId` stale-guard (`search_screen.dart`'tan kopyala).
- Navigasyon yalnızca `context.go/push/pop`; nesne taşıma `extra:` ile.
- Yeni tam ekran rotası `app_router.dart`'a `parentNavigatorKey: rootNavigatorKey` ile eklenir.

## 8. Bitirme kontrolü

- [ ] Çıplak `Color(...)`/`Colors.*` yok (white/transparent hariç); çıplak `TextStyle` yerine GoogleFonts.
- [ ] Loading + error + empty üçü de var ve Türkçe.
- [ ] Uzun metinlerde ellipsis; küçük ekranda (klavye dahil) taşma yok.
- [ ] Görseller `SafeNetworkImage`; mounted/dispose tam.
- [ ] Yeni ekran, mevcut ekranların yanına konduğunda stil olarak ayırt edilemiyor.
- [ ] `flutter analyze` → 0 issue.
