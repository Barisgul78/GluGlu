// Rehber bilgi kartlarını (rehber_bilgileri) Firestore'a yükler.
// Varsayılan: DENEME — hiçbir şey yazmaz, sadece ne yapacağını listeler.
//   --yaz       gerçek yazım; mevcut dokümanı atlar
//   --guncelle  --yaz ile birlikte: mevcut dokümanın üzerine yazar (metin düzeltmesi için)
// Hiçbir şey silmez.
//
// Kullanım:
//   node yukle_rehber.js --key "C:\yol\servis-hesabi.json"
//   node yukle_rehber.js --key "C:\yol\servis-hesabi.json" --yaz
//   node yukle_rehber.js --key "C:\yol\servis-hesabi.json" --yaz --guncelle

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

// Yüklenecek dosya(lar); yeni konu eklenince buraya satır eklenir
const DOSYALAR = ['../rehber_colyak_nedir.json'];
const KOLEKSIYON = 'rehber_bilgileri';
const REQUIRED = ['id', 'konu_id', 'baslik', 'kategori', 'ozet', 'guncelleme_tarihi'];
const BATCH_LIMIT = 400; // Firestore batch üst sınırı 500

const args = process.argv.slice(2);
const keyIdx = args.indexOf('--key');
const keyPath = keyIdx >= 0 ? args[keyIdx + 1] : null;
const yaz = args.includes('--yaz');
const guncelle = args.includes('--guncelle');

if (!keyPath) {
  console.error('Kullanım: node yukle_rehber.js --key <servis-hesabi.json> [--yaz] [--guncelle]');
  process.exit(1);
}
if (guncelle && !yaz) {
  console.error('--guncelle yalnızca --yaz ile birlikte anlamlı. Deneme modunda ne olacağı zaten listelenir.');
  process.exit(1);
}

const key = JSON.parse(fs.readFileSync(path.resolve(keyPath), 'utf8'));
initializeApp({ credential: cert(key) });
const db = getFirestore();

function validate(dosya, items) {
  const errors = [];
  const seen = new Set();
  items.forEach((p, i) => {
    const etiket = `${dosya}[${i}] ${p.id || '(id yok)'}`;
    for (const k of REQUIRED) {
      if (typeof p[k] !== 'string' || p[k].trim() === '') errors.push(`${etiket}: '${k}' boş veya string değil`);
    }
    if (p.id && !/^[a-z0-9_]+$/.test(p.id)) errors.push(`${etiket}: id yalnızca küçük harf, rakam, _ içermeli`);
    if (p.id && seen.has(p.id)) errors.push(`${etiket}: tekrar eden id`);
    seen.add(p.id);
    if (typeof p.sira !== 'number') errors.push(`${etiket}: 'sira' sayı olmalı`);
    if (Number.isNaN(Date.parse(p.guncelleme_tarihi))) errors.push(`${etiket}: 'guncelleme_tarihi' geçerli bir tarih değil (örn. 2026-11-26)`);
    const b = p.bolumler;
    const ok = Array.isArray(b) && b.length > 0 && b.every((x) =>
      x && typeof x.baslik === 'string' && x.baslik.trim() !== '' &&
      typeof x.metin === 'string' && x.metin.trim() !== '');
    if (!ok) errors.push(`${etiket}: 'bolumler' dolu bir liste olmalı, her öğe {baslik, metin}`);
  });
  return errors;
}

// Dosyadaki id'yi doküman ID'si yapar, alanlara yazmaz; tarih string'i Timestamp'a çevrilir
function toDoc(p) {
  const { id, ...rest } = p;
  return { ...rest, guncelleme_tarihi: Timestamp.fromDate(new Date(p.guncelleme_tarihi)) };
}

async function main() {
  console.log(yaz ? '*** GERÇEK YAZIM MODU ***' : '--- DENEME (hiçbir şey yazılmayacak) ---');
  console.log(`Proje: ${key.project_id}`);
  if (yaz && guncelle) console.log('Mevcut dokümanların ÜZERİNE YAZILACAK (--guncelle)');
  console.log('');

  const yazilacak = [];
  let hata = false;

  for (const dosya of DOSYALAR) {
    const items = JSON.parse(fs.readFileSync(path.join(__dirname, dosya), 'utf8'));
    const errors = validate(dosya, items);
    if (errors.length) {
      hata = true;
      console.error(`${dosya}: ${errors.length} hata`);
      errors.forEach((e) => console.error('  - ' + e));
      continue;
    }

    const refs = items.map((p) => db.collection(KOLEKSIYON).doc(p.id));
    const snaps = await db.getAll(...refs);

    let yeni = 0, mevcut = 0;
    items.forEach((p, i) => {
      const var_ = snaps[i].exists;
      const yazilir = !var_ || guncelle;
      if (var_) mevcut++; else yeni++;
      console.log(`   ${!var_ ? '+' : guncelle ? '~' : '='} ${refs[i].path}` +
        `${var_ ? (guncelle ? ' (güncellenecek)' : ' (atlandı)') : ''}`);
      if (yazilir) yazilacak.push({ ref: refs[i], data: toDoc(p) });
    });
    console.log(`${dosya}: ${items.length} kart | yeni ${yeni} | zaten var ${mevcut}\n`);
  }

  if (hata) {
    console.error('Doğrulama hataları var, hiçbir şey yazılmadı.');
    process.exit(1);
  }
  if (!yaz) {
    console.log('Deneme bitti. Gerçekten yazmak için aynı komuta --yaz ekle.');
    return;
  }

  for (let i = 0; i < yazilacak.length; i += BATCH_LIMIT) {
    const batch = db.batch();
    yazilacak.slice(i, i + BATCH_LIMIT).forEach((y) => batch.set(y.ref, y.data));
    await batch.commit();
  }
  console.log(`Bitti: ${yazilacak.length} doküman yazıldı.`);
}

main().catch((e) => {
  console.error('Hata:', e.message);
  process.exit(1);
});
