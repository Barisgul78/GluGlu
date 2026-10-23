---
name: glufree-firestore
description: GluFree'nin Firestore veri sözleşmesi ve sorgu desenleri. Firestore okuyan/yazan, servis ekleyen, model değiştiren veya rules'a dokunan HER işte koda başlamadan önce kullan. Alan adı uydurma, yanlış koleksiyon sorgulama ve rules ihlali hatalarını önler.
---

# GluFree Firestore Sözleşmesi

Bu skill, kod yazmadan önce cevaplanması gereken üç soruyu kapatır:
**hangi koleksiyon, hangi alan adları, yazmaya iznin var mı?**

## 0. Demir kurallar

1. Alan adları **Türkçe snake_case**. İngilizce alan adı uydurma — yazdığın veri hiçbir ekranda görünmez.
2. Ürünler `collectionGroup('marka_urunleri')` ile okunur. Kök `urunler` koleksiyonunu sorgulayan kod yazma (şemada var, kod kullanmaz).
3. Makaleler (Tips) Firestore'da **değil** — `TipsService._tips` hardcoded. Firestore'da yalnızca favori makale ID listesi tutulur.
4. Tarihler her zaman `Timestamp` (`Timestamp.fromDate(...)`), asla string.
5. Koleksiyon adları `lib/core/constants/app_constants.dart`'taki `k...Collection` sabitlerinden. String literal yazma.
6. Firestore çağrısı yalnızca `data/services/` altındaki statik servis sınıflarında. Ekran dosyasına `FirebaseFirestore.instance` yazılmaz (tek meşru istisna: servisten dönen stream'i `StreamBuilder`'a vermek).

## 1. Koleksiyon rehberi

### `markalar/{marka}/marka_urunleri/{docId}` — ürünler (gerçek kaynak)

| Alan | Tip | Not |
|---|---|---|
| `id` | String | Doküman içinde ayrıca tutulur; `whereIn('id', ...)` buna dayanır |
| `urun_adi` | String | Karışık büyük/küçük harfli — prefix sorgusu çalışmaz |
| `marka` | String | |
| `resim` | String | URL **veya** asset adı → UI'da her zaman `SafeNetworkImage` |
| `icindekiler` | String? | |
| `barkod` | String? | |
| `durum` | String | `"GUVENLI"` \| `"RISKLI"` \| `"BILINMIYOR"` → `ProductStatus` enum |
| `kategori` | String | Model varsayılanı `'Genel'` |
| `kalori`, `protein`, `karbonhidrat` | String | Model'de `nutrition` map'ine gider, varsayılan `'N/A'` |

Model: `lib/features/search/data/models/product.dart`. Rules: okuma herkese açık, **yazma kapalı**.
collectionGroup sorguları için rules'ta wildcard kuralı ve `firestore.indexes.json`'da `urun_adi` fieldOverride mevcut.

### `mekanlar/{id}` — mekanlar

`ad`, `aciklama`, `resim`, `puan` (num — UI string'e çevirir), `mesafe` (String, örn. "1.2 km"), `adres`, `rozet` (varsayılan "Glutensiz"), `etiketler` (List\<String\>).
Model: `venue.dart`. Rules: okuma açık, **yazma kapalı**. Koordinat alanı **yok** — haritada mekan pin'i gerektiren iş için önce kullanıcıya sor.

### `favoriler/{userId}` — kullanıcı favorileri

`urun_idleri: []`, `mekan_idleri: []`, `makale_idleri: []`.
Rules: yalnızca `auth.uid == userId`. Servis: `favorites_service.dart`.
Güncelleme deseni her zaman:

```dart
// ekleme — doküman yoksa oluşturur
docRef.set({alan: FieldValue.arrayUnion([id])}, SetOptions(merge: true));
// çıkarma — doküman var varsayılır
docRef.update({alan: FieldValue.arrayRemove([id])});
```

### `users/{userId}` — profil

`ad`, `soyad`, `email`, `fotoURL` (null olabilir), `dogumTarihi` (Timestamp), `kullaniciAdi`, `olusturmaTarihi` (serverTimestamp), `anonim` (bool), `tani_tarihi` (Timestamp, opsiyonel), `istatistikler` (map, aşağıda).
Rules: yalnızca `auth.uid == userId`. Servisler: `profile_service.dart`, `stats_service.dart`, `auth_service.dart`.

`istatistikler` map'i prefix desenli (`StatsService`):
- Basit sayaç: `{prefix}_toplam`, `{prefix}_bu_ay`, `{prefix}_ay_anahtari` ("2026-07") — prefix örn. `aranan_urun`
- Benzersiz sayaç: `{prefix}_idleri` (List) + `_bu_ay` + `_ay_anahtari` — prefix'ler: `kesfedilen_mekan`, `tiklanan_urun`, `okunan_makale`
- Streak: `giris_serisi`, `giris_serisi_rekor`, `son_giris_tarihi` (Timestamp)

### `usernames/{username}` — kullanıcı adı rezervasyonu

Tek alan: `{ uid }`. Rules: okuma herkese açık (kayıt öncesi kontrol), create yalnızca kendi uid'iyle ve `hasOnly(['uid'])`, update/delete kapalı.
Kontrol `AuthService.isUsernameTaken` — where sorgusu değil, doküman ID ile tekil `get()`.

## 2. Sorgu desenleri (kopyala-uyarla)

**whereIn 30 limiti** — uzun ID listesi parçalanır, paralel sorgulanır (`FavoritesService.fetchProductsByIds`):

```dart
final chunks = _chunk(ids, 30);
final results = await Future.wait(chunks.map((chunk) =>
    FirebaseFirestore.instance
        .collectionGroup('marka_urunleri')
        .where('id', whereIn: chunk)
        .get()));
```

**Sayfalama** — `Paginated<T>` (`core/utils/paginated.dart`) + `startAfterDocument` (`VenuesService.fetchPage`):

```dart
Query ref = col.limit(limit);
if (startAfter != null) ref = ref.startAfterDocument(startAfter);
// dönüş: Paginated(items, lastDocument, hasMore: docs.length == limit)
```

**Sayaç/read-modify-write** — her zaman `runTransaction` + `SetOptions(merge: true)` (`StatsService._bumpCounter` örnek). Transaction dışında get→set yazma; iki cihaz aynı anda yazarsa sayaç kaybolur.

**Arama** — client-side, bilinçli: tüm `marka_urunleri` çekilir (~33 ürün), Dart'ta `contains` ile filtrelenir (`SearchService.searchByName`). Server-side prefix sorgusuna çevirme — veri karışık harfli, sorgu boş döner. Ürün sayısı ~500'ü geçmedikçe dokunma.

**Model okuma toleransı** — `fromFirestore` her alanda varsayılanlı:

```dart
name: data['urun_adi'] ?? '',
tags: List<String>.from(data['etiketler'] ?? []),
```

Eksik alanlı eski doküman crash ettirmemeli.

## 3. Rules'un dayattığı akış kuralları

- **Client yazamaz:** `urunler`, `marka_urunleri`, `mekanlar`. "Ürün/mekan ekleme" özelliği client-side imkânsız — permission-denied. Böyle bir istekte dur, kullanıcıya rules değişikliği gerektiğini söyle, onaysız `firestore.rules` değiştirme.
- **Hesap silme sırası değişmez** (`AuthService.deleteAccount`): önce `usernames` → `favoriler` → `users`, en son `user.delete()`. Auth önce silinirse `auth.uid == userId` şartı sağlanamaz, dokümanlar öksüz kalır.
- **Kayıt rollback deseni** (`AuthService.signUp`): Auth hesabı oluşturulur → Firestore yazımı başarısızsa hesap silinir + rethrow. Yeni "kayıt sırasında X de oluştur" işi bu try/catch'in içine eklenir, dışına değil.
- **Kullanıcı adı değişikliği** (`updateProfileBasics`): eski rezervasyon silme + yeni rezervasyon + profil güncelleme tek `batch`'te. Bu atomikliği bozma.
- **`currentUserId == null`** her serviste ele alınır: favori işlemleri sessizce erken döner, UI tarafı "giriş yapmanız gerekiyor" gösterir. Yeni kullanıcıya-özel serviste aynı desen.

## 4. Yeni alan / koleksiyon ekleme protokolü

1. **DUR — önce kullanıcıya sor.** Şema değişikliği konsol verisi + rules + eski dokümanlarla uyum demektir; tek başına karar verilmez.
2. Onay geldiyse: alan adı Türkçe snake_case, mevcut adlandırmayla tutarlı (`..._idleri`, `..._tarihi`, `olusturmaTarihi` gibi mevcut karışıklığa dikkat — users koleksiyonunda camelCase alanlar da var, o koleksiyonun kendi iç tutarlılığını izle).
3. Yazma: `SetOptions(merge: true)` — mevcut dokümanları ezmez.
4. Okuma: toleranslı varsayılan — alan olmayan dokümanlar crash etmez.
5. Rules kontrolü: yeni koleksiyonsa `firestore.rules`'a kural öner (varsayılan: kullanıcıya-özel ise `auth.uid == userId`, katalog verisiyse read-only).
6. `CLAUDE.new.md` §3'teki sözleşme tablosunu güncelle.

## 5. Bitirme kontrolü

- [ ] Sorgulanan koleksiyon/alan adları bu dosyadaki tablolarla birebir eşleşiyor.
- [ ] Yazılan koleksiyon rules'ta client yazımına açık.
- [ ] `whereIn` ≤ 30 / chunk'lı; liste sorguları limitli.
- [ ] Tarihler Timestamp; sayaçlar transaction'lı; array alanları arrayUnion/arrayRemove + merge.
- [ ] `fromFirestore` toleranslı; `currentUserId == null` ele alınmış.
- [ ] `flutter analyze` temiz.
