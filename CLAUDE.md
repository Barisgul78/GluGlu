# GluGlu — Çalışma Kılavuzu (Operating Manual)

Bu dosya, bu repoda çalışan herhangi bir modelin **kod yazmadan önce** okuduğu varsayılan tek kaynaktır. Amaç: bu projeyi hiç görmemiş bir modelin, deneyimli bir geliştiricinin seviyesinde iş çıkarması. Kurallar "öneri" değil; her biri gerçekten yapılmış bir hatayı veya bilinçli bir kararı kodluyor.

---

## 0. Tek paragraf özet

GluGlu: çölyak/gluten hassasiyeti olan kullanıcılar için glutensiz ürün + mekan keşif uygulaması. Flutter (iOS/Android), Firebase Auth + Firestore, go_router, Riverpod (sınırlı), UI dili Türkçe. Feature-first mimari, statik-metotlu servis katmanı, ekranlarda `StatefulWidget + setState`. Tek zorunlu kalite kapısı: `flutter analyze` temiz. Test klasörü **yok** (bkz. §2.5).

---

## 1. Gerçeklik Haritası

Bu bölüm dokümantasyonun değil **kodun** söylediğini yazar. Şüphede kaldığında koda güven, bu tabloya bak, eski dokümanlara güvenme.

| Konu | Gerçek durum |
|---|---|
| Ürün verisi | `collectionGroup('marka_urunleri')` üzerinden okunur (`search_service.dart`, `favorites_service.dart`). Kök `urunler` koleksiyonu şemada/rules'ta var ama **kod onu sorgulamaz.** |
| Ürün arama | Server-side prefix sorgusu **bilinçli olarak yok** — veri karışık büyük/küçük harfli, toplam ~33 ürün; tümü çekilip Dart tarafında filtrelenir. Bunu "optimize etme". |
| Makaleler (Tips) | Firestore'da **değil** — `TipsService._tips` hardcoded liste (`tips_service.dart`). Favori makaleler sadece ID listesi olarak Firestore'a yazılır, içerik lokalden filtrelenir. |
| Mekan favorileri | Şemada `mekan_idleri` alanı var ama UI **placeholder** — Favoriler > Mekanlar sekmesi her zaman boş durum gösterir. Implement edilmedi, bug değil. |
| Riverpod | Sadece `themeModeProvider` + `localeProvider`. Ekranlar `setState` ile çalışır. **Ekranları Riverpod'a taşıma** — istenirse ayrı, onaylı iş. |
| Koyu tema | `darkTheme: AppTheme.light` — bilinçli. Koyu palet tanımlanana kadar böyle kalacak. |
| Test | `test/` klasörü yok. `flutter test` çalıştırılamaz. "Testler geçiyor" cümlesi bu repoda kurulamaz. |
| Anasayfa "Popüler Konular" | Hardcoded 4 kart, makale sayıları sahte ("12 makale"). Bilinen borç. |
| Anasayfa "Haftanın Markası" | Boş stub (`_buildHaftaninMarkasi` sadece SizedBox döner). |
| Profil rozetleri | Statik placeholder — onaylı karar, veri modeli yok. |
| Sağlık kartı | Gerçek: `users/{uid}.saglik_karti` map'i (`/saglik-karti` rotaları, `health_card_*` dosyaları). Paylaşım PNG, `share_plus` ile. Spec: `docs/superpowers/specs/2026-11-14-saglik-karti-design.md`. |
| Barkod tarayıcı | **Asla eklenmeyecek.** Kamera izni/entegrasyonu planlanmıyor. Placeholder bile ekleme. |
| Onboarding | Debug'da her açılışta gösterilir, release'te bir kez (`kReleaseMode` kontrolü `main.dart`'ta). Debug'da her seferinde onboarding görmek bug değil. |
| Manrope fontu | Tüm uygulamanın tek fontu: `GoogleFonts.manrope(...)`. `assets/fonts/` pubspec'te `assets:` altında; `google_fonts` bundle'lı `Manrope-<Ağırlık>.ttf` dosyalarını bulur, ağ isteği yapmaz (çevrimdışı çalışır). Başlık/gövde ayrımı aileden değil ağırlık ve boyuttan gelir. |

---

## 2. Mimari ve Konvansiyonlar

### 2.1 Klasör yapısı (feature-first)

```text
lib/
  core/
    routing/        app_router.dart (createAppRouter), main_shell.dart
    theme/          app_colors.dart (k-sabitleri), app_theme.dart (AppTheme.light)
    widgets/        custom_button.dart (AppButton/AppOutlinedButton), custom_text_field.dart,
                    safe_network_image.dart, bubble_background.dart
    utils/          validators.dart, string_utils.dart (initials), date_utils.dart (formatDate),
                    snackbars.dart (showErrorSnackBar/showInfoSnackBar),
                    firebase_error_mapper.dart, paginated.dart (Paginated<T>)
    constants/      app_sizes.dart (AppSizes), app_constants.dart (koleksiyon adları, limitler)
    providers/      theme_provider.dart, locale_provider.dart
    services/       location_service.dart
  features/
    <feature>/
      data/models/          (immutable model + fromFirestore factory)
      data/services/        (statik metotlu servis sınıfı)
      presentation/screens/
      presentation/widgets/ (feature'a özel, birden çok ekranda kullanılan parçalar)
  main.dart
  firebase_options.dart
```

Yeni dosya eklerken: önce feature sınırını belirle, dosyayı ilgili feature altına koy. İki feature'ın ortak kullandığı widget/util → `core/`'a taşınır (örn. `SafeNetworkImage`).

### 2.2 Servis deseni (bu reponun "repository"si)

Repo Clean Architecture'ın tam halini **kullanmaz** — use case/repository interface katmanı yok. Yerleşik desen:

```dart
class XService {
  XService._();                    // instance yok, statik sınıf
  static Future<Sonuc> metod() ...  // Firestore SADECE burada
}
```

- Servis `BuildContext`, widget veya Flutter UI importu **bilmez**.
- Firestore/Auth çağrısı ekran dosyasına yazılmaz — mevcut ekranlardaki tek istisna `favorites_screen.dart`'ın `StreamBuilder(stream: FavoritesService.favoritesStream(...))` kullanımı; stream servisten gelir, sorgu yine servistedir.
- Koleksiyon adları `app_constants.dart`'taki `k...Collection` sabitlerinden gelir; string literal koleksiyon adı yazma.
- Hata stratejisi: servis hatayı **yutmaz** — ya `rethrow` eder ya anlamlı exception fırlatır (`throw Exception('kullanici-adi-alinmis')` gibi kod-string deseni mevcut). Yakalayıp `debugPrint` + güvenli varsayılan dönmek yalnızca "yokluk normaldir" durumlarında meşru (örn. `LocationService` null döner).

### 2.3 Ekran deseni

- `StatefulWidget` + `setState`. Form/geçici state lokalde kalır.
- `initState`'te veri yükleme başlatılır; her `await` sonrası UI'a dokunmadan önce `if (!mounted) return;`.
- Her `TextEditingController`, `FocusNode`, `PageController`, `ScrollController`, `Timer` → `dispose()`'da temizlenir.
- Debounce'lu arama için yerleşik desen `search_screen.dart`'ta: 500ms `Timer` + artan `_searchRequestId` ile stale cevap reddi. Yeni arama/async liste yazarken bu deseni kopyala.
- Her async liste üç durumu gösterir: **loading** (CircularProgressIndicator, `color: kPrimary`), **error** (kullanıcı diliyle mesaj + mümkünse retry), **empty** (Türkçe tek satır açıklama). Üçünden biri eksikse iş bitmemiştir.

### 2.4 Routing (go_router)

- Tüm rotalar `core/routing/app_router.dart` içinde, `createAppRouter()`'da tanımlı. Başka yerde `GoRoute` tanımlama.
- `Navigator.push` **yasak** — `context.go` (sekme değişimi), `context.push` (üste açılan ekran), `context.pop()` (geri).
- 5 sekme `StatefulShellRoute.indexedStack` ile: `/home`, `/search`, `/rehber`, `/favorites`, `/profile` (`_branchPaths` sırası `MainShell`'deki `NavigationBar` destinations sırasıyla **aynı olmalı**).
- Sekme çubuğunun ÜSTÜNDE açılması gereken her rota (`/urun`, `/settings`, `/profile/edit`, `/tips`, `/tips/detay`, `/venues`, `/venues/map`) → `parentNavigatorKey: rootNavigatorKey` almak **zorunda**. Bu satır unutulursa ekran sekme kabuğunun içinde, altta NavigationBar ile açılır.
- Ekranlar arası nesne taşıma: `context.push('/urun', extra: product)` + rota builder'da `state.extra as Product` cast. Yeni rota eklerken aynı desen.
- Auth redirect mantığı `redirect` callback'te; `GoRouterRefreshStream` (bilinçli `ChangeNotifier`, Riverpod'a taşınmaz) Firebase Auth stream'ini dinler. **Bu callback'e dokunacak her değişiklik önce onay ister** (bkz. §6).

### 2.5 Test ve doğrulama gerçeği

- Zorunlu kapı: `flutter analyze` → **0 issue**. Her anlamlı değişiklikten sonra çalıştır, çıktıyı raporla.
- `test/` klasörü yok. Test yazman istenirse önce klasörü oluştur, `flutter test` o zaman anlam kazanır. İstenmeden test altyapısı kurma.
- Testin yerini tutan şey: **manuel smoke listesi**. Değişen akışı adım adım yaz ("Makale detayında bookmark'a bas → Favoriler > Makaleler'de görünsün" formatında) ve teslimde kullanıcıya ver — cihazda koşan kullanıcıdır.

### 2.6 Kod stili

- Yorumlar Türkçe, kısa, **sadece koddan okunamayan kısıtı** anlatır (örn. "whereIn en fazla 30 eleman kabul eder"). Kodun yaptığını tekrar eden yorum yazılmaz.
- `print()` yasak → `debugPrint()`. Boş `catch` yasak.
- Dosya `snake_case.dart`, sınıf `PascalCase`, üye `camelCase`. UI metinleri ve Firestore alan adları Türkçe.
- `const` constructor ve immutable model varsayılan.
- Commit mesajları Türkçe, kısa, tek satır ağırlıklı (`bottom_picker eklendi`, `firebase mantık hataları düzeltimi` tarzı). Conventional-commit öneki (`feat:`) kabul ama şart değil.

### 2.7 Kullanıcının çalışma şekli

- Çok dosyalı / davranış değiştiren işler **önce plan mode**: kapsam + etkilenen dosyalar + mimari karar & gerekçe + breaking change'ler açıkça + sıralı adım listesi. Onaysız implementasyona geçilmez; plandan sapma açıkça söylenir.
- Orta/büyük özellikler için tasarım spec'i `docs/superpowers/specs/YYYY-MM-DD-<konu>-design.md` olarak yazılır (örneği repoda var). Spec "Kapsam Dışı" ve "Doğrulama" bölümü içerir — kapsam dışı bölümü scope creep'in freni.
- `/simplify` tarzı incelemelerde: bulguları **önce sun, onay bekle**, sonra uygula.
- Kullanıcı Windows'ta çalışır (PowerShell). Path'lerde `C:\projeler\glutenApp`, komutlarda POSIX varsayma.

---

## 3. Veri Sözleşmesi (Firestore)

Alan adları **Türkçe snake_case**. İngilizce alan adı üretmek bu repodaki en pahalı hata sınıfıdır — yazdığın veri hiçbir ekranda görünmez, okuduğun alan hep null gelir.

### Koleksiyonlar ve gerçek alanlar

**`markalar/{marka}/marka_urunleri/{docId}`** — ürünlerin gerçek kaynağı (collectionGroup ile sorgulanır):
`id` (String — doküman içinde ayrıca tutulur, favoriler bu `id` ile eşleşir), `urun_adi`, `marka`, `resim` (URL **veya** asset adı — bkz. SafeNetworkImage), `icindekiler`, `barkod`, `durum` (`"GUVENLI" | "RISKLI" | "BILINMIYOR"`), `kategori`, `kalori`, `protein`, `karbonhidrat`.

**`mekanlar/{id}`**: `ad`, `aciklama`, `resim`, `puan` (num → UI'da string'e çevrilir), `mesafe` (String), `adres`, `rozet`, `etiketler` (List).

**`favoriler/{userId}`**: `urun_idleri: []`, `mekan_idleri: []`, `makale_idleri: []` — hepsi `arrayUnion`/`arrayRemove` + `SetOptions(merge: true)` ile güncellenir.

**`users/{userId}`**: `ad`, `soyad`, `email`, `fotoURL`, `dogumTarihi` (Timestamp), `kullaniciAdi`, `olusturmaTarihi` (serverTimestamp), `anonim` (bool), `tani_tarihi` (Timestamp, opsiyonel), `telefon` (String, opsiyonel, `+905XXXXXXXXX`, doğrulanmamış), `sehir` (String, opsiyonel), `saglik_karti` (map, opsiyonel: `ad_soyad`, `ihtiyaclar` [`COLYAK`/`GLUTEN_HASSASIYETI`/`BUGDAY_ALERJISI`/`DIGER`], `tuketilemeyenler`, `capraz_temas` bool, `not`, `guncelleme_tarihi` Timestamp), `istatistikler` (map — `StatsService`'in prefix'li sayaç alanları: `aranan_urun_toplam`, `kesfedilen_mekan_idleri`, `giris_serisi`, ...).

**`usernames/{username}`**: `{ uid }` — kullanıcı adı rezervasyonu. Sadece create; update/delete client'tan kapalı (hesap silme akışındaki delete rules'ta ayrıca ele alınır).

### Rules'un koda dayattığı kurallar

- `urunler`, `marka_urunleri`, `mekanlar`: **client yazamaz** (`write: false`). Ürün/mekan ekleyen-güncelleyen bir özellik client-side yazılamaz; veri konsoldan girilir. Böyle bir istek gelirse bunu söyle, rules değişikliği öner, onaysız `firestore.rules` değiştirme.
- `favoriler/{userId}` ve `users/{userId}`: sadece `auth.uid == userId`. Servislerde `AuthService.currentUserId` null ise sessizce erken dönme deseni bundandır.
- Hesap silme sırası **değişmez**: önce Firestore dokümanları (username, favoriler, users), en son `user.delete()` — Auth önce silinirse rules `auth.uid == userId` şartını sağlayamaz ve dokümanlar öksüz kalır.

### Sorgu desenleri

- `whereIn` limiti 30 → uzun liste 30'luk parçalanıp `Future.wait` ile paralel sorgulanır.
- **Ürün sorgularında `where()`/`whereIn` kullanma:** `collectionGroup('marka_urunleri')` üzerinde filtre için indeks yok (`firestore.indexes.json`'da yalnızca `urun_adi` var), sorgu `failed-precondition` verir. İndekssiz `get()` + Dart'ta filtre (`SearchService._fetchAll`, `FavoritesService.fetchProductsByIds`).
- Sayfalama → `Paginated<T>` (`core/utils/paginated.dart`) + `startAfterDocument` (`VenuesService.fetchPage` örnek).
- Sayaç/streak yazımı → `runTransaction` + `SetOptions(merge: true)` (`StatsService` örnek). Sayaç eklerken bu deseni kullan, read-modify-write'ı transaction dışında yapma.
- Tarih alanları **her zaman** `Timestamp` (`Timestamp.fromDate`), asla string.
- Yeni alan eklerken: yazma tarafı `merge: true`, okuma tarafı toleranslı (`data['alan'] ?? varsayılan`) — eski dokümanlarda alan yoktur.
- `collectionGroup('marka_urunleri')` sorguları için rules'taki wildcard kuralı ve `firestore.indexes.json`'daki fieldOverride zaten mevcut; yeni collectionGroup sorgusu eklersen ikisini de kontrol et.

---

## 4. Bilinen Tuzaklar

Her biri "zayıf modelin yapacağı hata → önleyen kural" formatında. Bunlar teorik değil; kod/şema bu hataları davet ediyor.

1. **Ürünleri `urunler` koleksiyonundan sorgulamak.** Şema dokümanları `urunler`'i tarif eder ama kod okumaz. → *Kural: ürün okuyan her sorgu `collectionGroup('marka_urunleri')` üzerinden; yeni sorgu yazmadan önce `search_service.dart`/`favorites_service.dart`'a bak.*
2. **Tips/makaleleri Firestore'dan çekmeye çalışmak.** → *Kural: makale içeriği `TipsService.getAll()` (hardcoded); Firestore'da yalnızca favori ID listesi var. Firestore'a taşıma ayrı, onaylı iş.*
3. **`Firebase.initializeApp(options: DefaultFirebaseOptions...)` yazmak.** Android'de google-services.json native tarafta `[DEFAULT]` app'i zaten kurar; options ile init `duplicate-app` fırlatır. → *Kural: `main.dart`'taki parametresiz çağrıya dokunma.*
4. **Yeni rotaya `parentNavigatorKey: rootNavigatorKey` koymamak.** Ekran sekme kabuğunun içinde açılır, altta NavigationBar kalır. → *Kural: tam ekran açılan her rota rootNavigatorKey alır; sekme rotaları yalnızca `_branchPaths`'takilerdir.*
5. **`Navigator.push(MaterialPageRoute(...))` kullanmak.** Eski spec'lerde bile geçebilir. → *Kural: yalnızca `context.go/push/pop`. Rota yoksa `app_router.dart`'a ekle.*
6. **İngilizce Firestore alan adı uydurmak** (`name`, `created_at`, `favorites`...). → *Kural: alan adları §3'teki listeden; yeni alan Türkçe snake_case ve önce kullanıcıya bildirilir.*
7. **Aramayı "düzeltmek" — server-side prefix/orderBy sorgusuna çevirmek.** Veri karışık harfli, sorgu boş döner. → *Kural: `SearchService.searchByName` client-side filtreler; ürün sayısı belirgin büyüyene kadar (>~500) dokunma.*
8. **`await` sonrası `mounted` kontrolsüz `setState`/`context` kullanımı.** → *Kural: her await'ten sonra UI'a dokunmadan önce `if (!mounted) return;`. `finally` bloklarında da (`if (mounted) setState(...)`).*
9. **Controller/Timer dispose unutmak.** → *Kural: `initState`'te oluşturulan her controller/focus node/timer `dispose()`'da kapatılır; PR'dan önce say: oluşturulan N, dispose edilen N.*
10. **Renk/font'u elle yazmak** (`Colors.grey`, `Color(0xFF...)`, çıplak `TextStyle`). → *Kural: renkler `app_colors.dart` k-sabitlerinden; tüm metin `GoogleFonts.manrope` (başlık bold/w700, gövde w500); boşluk/radius/font boyutu `AppSizes`'tan. Mevcut istisnalar (`Colors.white`, `Colors.transparent`) kabul.*
11. **Ekranları Riverpod'a "modernize" etmek.** → *Kural: ekran state'i `setState` ile kalır; Riverpod yalnızca tema/dil. Genişletme ancak açık istekle.*
12. **Tema paletini veya `AppTheme`'i değiştirmek.** → *Kural: `app_colors.dart` değerleri donmuş. Yeni renk gerekiyorsa mevcut sabitlerden seç; yoksa sor.*
13. **`whereIn`'e 30'dan uzun liste vermek.** Sorgu runtime'da patlar. → *Kural: 30'dan uzun `whereIn` listesini parçala. Ürün sorgularında ise hiç `where` kullanma (indeks yok), `FavoritesService.fetchProductsByIds` gibi indekssiz çekip Dart'ta filtrele.*
14. **"Testler geçti" demek.** Test yok. → *Kural: doğrulama iddiası yalnızca `flutter analyze` çıktısı + manuel smoke listesiyle kurulur.*
15. **Client'tan `mekanlar`/`marka_urunleri`'ne yazan özellik tasarlamak.** Rules sessizce reddeder (permission-denied). → *Kural: bu koleksiyonlara yazma isteği geldiğinde dur, §6'ya git.*
16. **Barkod tarayıcı önermek/eklemek.** → *Kural: kapsam dışı, kalıcı karar. Öneri olarak bile getirme.*
17. **UI'a İngilizce metin eklemek.** → *Kural: kullanıcıya görünen her string Türkçe. Hata mesajları teknik değil, kullanıcı diliyle (`FirebaseErrorMapper` örnek).*
18. **Hesap silme/username değişikliği sırasını bozmak.** → *Kural: `AuthService.deleteAccount` ve `updateProfileBasics`'teki sıra ve batch yapısı korunur; bu metotlara dokunan değişiklik önce onay ister.*
19. **`resim` alanını her zaman URL sanmak.** URL veya asset adı olabilir. → *Kural: network görsel her yerde `SafeNetworkImage` ile gösterilir, çıplak `Image.network` yazılmaz.*
20. **Onboarding'in debug'da hep açılmasını "bug" diye düzeltmek.** → *Kural: `kReleaseMode` kontrolü bilinçli; dokunma.*
21. **pubspec sürümlerini, firebase config'i, android/ios native ayarlarını "iyileştirmek".** → *Kural: bu dosyalar yalnızca açık istek + gerekçeyle değişir.*

---

## 5. Kalite Çıtası — Teslimat Başına Kontrol Listeleri

"İyi", "temiz", "sağlam" gibi sıfatlar geçersiz; aşağıdaki maddeler tek tek işaretlenebilir olmalı. Bir madde sağlanmıyorsa iş bitmemiştir, ya tamamla ya da neden sağlanmadığını açıkça yaz.

### 5.1 Yeni ekran / ekran değişikliği
- [ ] `Scaffold(backgroundColor: kBackground)` + içerik `SafeArea` içinde (CustomScrollView kullanan ekranlarda SliverAppBar deseni kabul).
- [ ] Async veri için üç durum da render ediliyor: loading / error (Türkçe mesaj) / empty (Türkçe mesaj).
- [ ] Her await sonrası `mounted` kontrolü var; oluşturulan tüm controller'lar dispose ediliyor.
- [ ] Renkler yalnızca `app_colors.dart` sabitlerinden; tüm metin `GoogleFonts.manrope`; ölçüler `AppSizes`'tan.
- [ ] Uzun metinlerde `maxLines` + `TextOverflow.ellipsis`; küçük ekranda taşma yok (klavye açıkken dahil — form varsa scroll edilebilir).
- [ ] Rota `app_router.dart`'a eklendi; tam ekransa `parentNavigatorKey: rootNavigatorKey` var; navigasyon `context.go/push/pop`.
- [ ] Firestore/Auth çağrısı ekranda yok — servis üzerinden.
- [ ] Kullanıcıya görünen tüm metinler Türkçe.
- [ ] `flutter analyze` → 0 issue (çıktı raporda).
- [ ] Manuel smoke listesi yazıldı (adım adım, beklenen sonuçla).

### 5.2 Yeni/değişen servis metodu
- [ ] Statik sınıf deseni (`Service._()`); Flutter UI importu yok.
- [ ] Koleksiyon adı `app_constants.dart` sabitinden.
- [ ] `currentUserId == null` durumu ele alınmış (erken dön veya anlamlı hata — mevcut desenle tutarlı).
- [ ] Hata yutulmuyor: rethrow / anlamlı exception / bilinçli-null (yorumla gerekçeli).
- [ ] Yazmalar `merge: true` veya `update` bilinçli seçilmiş; sayaç/read-modify-write ise transaction içinde.
- [ ] Sorgu limitli (limit/pagination) ve rules'a uygun (yazılamayan koleksiyona yazmıyor).
- [ ] `whereIn` kullanılıyorsa 30'luk chunk deseni uygulanmış.

### 5.3 Yeni/değişen model
- [ ] Immutable, `const` constructor.
- [ ] `fromFirestore` her alanda toleranslı (`?? ''` / `?? 0` / boş liste) — eksik alanlı doküman crash ettirmez.
- [ ] Alan adları §3'teki gerçek Firestore adlarıyla birebir; Dart tarafı camelCase İngilizce olabilir (mevcut desen: `urun_adi` → `name`).
- [ ] Tarihler `Timestamp` ↔ `DateTime` dönüşümüyle.

### 5.4 Bugfix
- [ ] Hata önce yeniden üretildi/nedeni koddan gösterildi (dosya:satır) — tahminle yama yok.
- [ ] Kök neden bir cümleyle raporda: "X çünkü Y".
- [ ] Diff minimal: davranışı değişen satırlar dışında refactor/format değişikliği yok.
- [ ] Aynı hatanın diğer örnekleri arandı (grep) — varsa ya düzeltildi ya listelendi.
- [ ] `flutter analyze` temiz + değişen akış için smoke adımı yazıldı.

### 5.5 Plan / spec çıktısı
- [ ] Kapsam ve etkilenen dosyalar listeli.
- [ ] Mimari kararlar gerekçeli; mevcut davranışta değişecek noktalar **breaking** etiketiyle işaretli.
- [ ] "Kapsam Dışı" bölümü var (neye dokunulmayacağı yazılı).
- [ ] Sıralı, kod yazmadan önce doğrulanabilir adım listesi var.
- [ ] "Doğrulama" bölümü: analyze + somut smoke adımları.

### 5.6 Commit
- [ ] Türkçe, kısa, yapılan işi söyler; tek commit tek mantıksal iş.
- [ ] `flutter analyze` temiz olmadan commit önerilmez.

---

## 6. Belirsizlikte Ne Yapılır — Eskalasyon Kuralları

Sıralı karar ağacı. "Sanırım", "muhtemelen" ile ilerleme; kural hangi kapıya düşüyorsa onu uygula.

**Sormadan İLERLE (kendi başına karar ver, kararı raporda belirt):**
- Mevcut bir desenin birebir tekrarı (yeni kart, yeni servis metodu, mevcut ekrana alan ekleme) — en yakın örneği kopyala, uyarl.
- İsimlendirme, dosya yerleşimi, widget parçalama gibi bu kılavuzun zaten cevapladığı konular.
- Dokümantasyon ile kod çelişiyorsa: **koda güven**, çelişkiyi raporunda tek cümleyle not et.

**DUR ve SOR (tek soruluk net bir soruyla; seçenek + önerini ver):**
- Firestore'a yeni koleksiyon/alan eklemek veya `firestore.rules` değiştirmek gerekiyorsa.
- `app_router.dart` redirect mantığına, `main.dart` init sırasına, `AuthService.deleteAccount`/`updateProfileBasics` akışına dokunmak gerekiyorsa.
- pubspec'e paket eklemek/sürüm değiştirmek gerekiyorsa (gerekçe + alternatifsizlik göster).
- İstek, §1/§4'teki bilinçli bir kararla çelişiyorsa (barkod, Riverpod'a taşıma, koyu tema, server-side arama...) — kararı hatırlat, gerçekten isteniyorsa onay al.
- UI metni/davranışı için tasarım kararı gerekiyorsa ve mevcut ekranlarda emsal yoksa.
- Görev, Firestore'da bulunmayan veriye ihtiyaç duyuyorsa (örn. mekan koordinatları — şemada yok).

**PLAN MODE'a GEÇ (onaysız kod yazma):**
- 3+ dosyaya dokunan her iş.
- Mevcut davranışı değiştiren her iş (refactor dahil).
- Yeni feature klasörü açan her iş.

**HİÇ YAPMA (istek gelse bile önce açık, tekrarlı onay iste):**
- Tema paleti değerlerini değiştirmek.
- Barkod tarayıcı eklemek.
- Native android/ios config, firebase_options, google-services değişikliği.
- `firestore.rules`'ta herkese-yazma açmak.

**Doğrulanamıyorsa:** `flutter analyze` çalıştırılamadıysa veya beklenmedik çıktı verdiyse — "tamamlandı" deme; durumu çıktıyla birlikte raporla ve neyin doğrulanamadığını açıkça yaz.

---

## 7. Komutlar (Windows)

```powershell
flutter analyze          # zorunlu kalite kapısı
flutter pub get          # pubspec değiştiyse (değiştirme kuralına dikkat)
flutter run              # manuel smoke — cihaz/emülatör kullanıcıda
```

- `flutter test` şu an anlamsız (test yok) — bkz. §2.5.
- Firestore verisi konsoldan yönetilir; seed/migration scripti repoda yok.

---

## 8. Proje Skill'leri

`.claude/skills/` altında üç proje skill'i var; ilgili iş türünde **koda başlamadan önce** oku:

- **`glufree-firestore`** — veri sözleşmesi, sorgu desenleri, rules etkileri. Firestore'a dokunan her işte.
- **`glufree-ui-kit`** — ev stili UI tarifleri: kart, badge, boş durum, snackbar, ekran iskeleti. UI üreten her işte.
- **`glufree-new-feature`** — uçtan uca özellik ekleme akışı: spec → katmanlar → rota → doğrulama. Yeni özellik/ekran işlerinde.
