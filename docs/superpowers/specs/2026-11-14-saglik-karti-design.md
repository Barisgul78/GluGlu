# Sağlık Kartı — Tasarım

## Amaç
Çölyak/gluten hassasiyeti olan kullanıcı, beslenme ihtiyaçlarını mekânlarda kolayca göstermek için kişisel bir "sağlık kartı" oluşturur, görüntüler, tam ekran gösterir ve görsel olarak paylaşır. Profil ekranındaki "Sağlık kartım" butonu (şu an "Yakında") bu akışa bağlanır.

## Kapsam
- **Oluştur/düzenle formu:** Ad soyad*, Beslenme ihtiyacı* (Çölyak / Gluten hassasiyeti / Buğday alerjisi / Diğer, çoklu), Tüketemediğin besinler*, Çapraz temas uyarısı (opsiyonel), Not (opsiyonel, ≤200).
- **Sağlık kartım ekranı:** yeşil başlıklı kart, kalem ile düzenleme, "Kartı tam ekran göster", "Kartı paylaş" (PNG).
- **Veri:** `users/{uid}.saglik_karti` map'i (yeni alan, onaylı). `firestore.rules` değişmez.

## Veri sözleşmesi
`users/{uid}.saglik_karti`: `ad_soyad` (String), `ihtiyaclar` (List<String>: `COLYAK`, `GLUTEN_HASSASIYETI`, `BUGDAY_ALERJISI`, `DIGER`), `tuketilemeyenler` (String), `capraz_temas` (bool), `not` (String, ≤200), `guncelleme_tarihi` (Timestamp).
Yazma `set(..., merge: true)`, okuma toleranslı. Alan yoksa "kart yok" → form gösterilir.

## Mimari kararlar
- Yeni feature klasörü yok, `profile` feature'ı altında. Servis: `ProfileService.saveHealthCard`, okuma mevcut `userStream`.
- Rotalar `app_router.dart`'a, hepsi `rootNavigatorKey`: `/saglik-karti`, `/saglik-karti/duzenle`, `/saglik-karti/tam-ekran`. Redirect'e dokunulmaz.
- Kart cümlesi: yazılan metin + " tüketemem." (ilk harf Türkçe kurala göre büyütülür).
- Paylaşım: `RepaintBoundary` → PNG → mevcut `share_plus` (yeni paket yok).
- Anonim/girişsiz kullanıcı karta giremez (bilgi snackbar'ı).

## Kapsam Dışı
Kartı silme, birden çok kart, QR/barkod (kalıcı karar: barkod yok), mekâna doğrudan gönderme, ekran parlaklığı/ekranı açık tutma (ek paket), karta fotoğraf, çok dillilik, `AuthService`, rules, pubspec.

## Doğrulama
`flutter analyze` + manuel smoke: oluştur (buton zorunlu alanlara göre aktifleşir) → kart görünür → Firestore'da `saglik_karti` alanları → yeniden açınca kart → düzenle → çapraz temas/not koşullu görünüm → tam ekran → PNG paylaşım → anonim hesapta engel → eski hesapta (alan yok) form.
