// Marka ürünlerini Firestore'a yükler.
// Varsayılan: DENEME — hiçbir şey yazmaz, sadece ne yapacağını listeler.
// Gerçek yazım için --yaz ekle. Mevcut dokümanın üzerine yazmaz, atlar. Hiçbir şey silmez.
//
// Kullanım:
//   node yukle.js --key "C:\yol\servis-hesabi.json"
//   node yukle.js --key "C:\yol\servis-hesabi.json" --yaz

const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Yüklenecek markanın satırı buraya yazılır, örn:
//   { klasor: 'altinkilic', ad: 'Altınkılıç', dosya: '../altinkilic_firestore.json' },
const BRANDS = [
  { klasor: 'altinkilic', ad: 'Altınkılıç', dosya: '../altinkilic_firestore.json' },
];
const REQUIRED = ['id', 'urun_adi', 'marka', 'resim', 'durum', 'kategori', 'kanit_cumlesi'];
const DURUMLAR = ['GUVENLI', 'RISKLI', 'BILINMIYOR'];
const BATCH_LIMIT = 400; // Firestore batch üst sınırı 500

const args = process.argv.slice(2);
const keyIdx = args.indexOf('--key');
const keyPath = keyIdx >= 0 ? args[keyIdx + 1] : null;
const yaz = args.includes('--yaz');

if (!keyPath) {
  console.error('Kullanım: node yukle.js --key <servis-hesabi.json> [--yaz]');
  process.exit(1);
}

const key = JSON.parse(fs.readFileSync(path.resolve(keyPath), 'utf8'));
initializeApp({ credential: cert(key) });
const db = getFirestore();

function validate(brand, items) {
  const errors = [];
  const seen = new Set();
  items.forEach((p, i) => {
    const etiket = `${brand.klasor}[${i}] ${p.id || '(id yok)'}`;
    for (const k of REQUIRED) {
      if (typeof p[k] !== 'string' || p[k].trim() === '') errors.push(`${etiket}: '${k}' boş veya string değil`);
    }
    if (p.id && !/^[a-z0-9_]+$/.test(p.id)) errors.push(`${etiket}: id yalnızca küçük harf, rakam, _ içermeli`);
    if (p.id && seen.has(p.id)) errors.push(`${etiket}: tekrar eden id`);
    seen.add(p.id);
    if (p.durum && !DURUMLAR.includes(p.durum)) errors.push(`${etiket}: geçersiz durum '${p.durum}'`);
    if (p.besin_degerleri !== undefined) {
      const m = p.besin_degerleri;
      const ok = m && typeof m === 'object' && !Array.isArray(m) &&
        Object.values(m).every((v) => typeof v === 'string' && v.trim() !== '');
      if (!ok) errors.push(`${etiket}: besin_degerleri string değerli bir map olmalı`);
    }
  });
  return errors;
}

async function main() {
  console.log(yaz ? '*** GERÇEK YAZIM MODU ***' : '--- DENEME (hiçbir şey yazılmayacak) ---');
  console.log(`Proje: ${key.project_id}\n`);

  const isler = [];
  let hata = false;

  for (const brand of BRANDS) {
    const items = JSON.parse(fs.readFileSync(path.join(__dirname, brand.dosya), 'utf8'));
    const errors = validate(brand, items);
    if (errors.length) {
      hata = true;
      console.error(`${brand.klasor}: ${errors.length} hata`);
      errors.forEach((e) => console.error('  - ' + e));
      continue;
    }

    const brandRef = db.doc(`markalar/${brand.klasor}`);
    const refs = items.map((p) => db.doc(`markalar/${brand.klasor}/marka_urunleri/${p.id}`));
    const [brandSnap, ...snaps] = await db.getAll(brandRef, ...refs);

    const yeni = [];
    const mevcut = [];
    items.forEach((p, i) => (snaps[i].exists ? mevcut : yeni).push({ ref: refs[i], data: p }));

    console.log(`${brand.klasor}: ${items.length} ürün | yeni ${yeni.length} | zaten var, atlanacak ${mevcut.length}` +
      ` | marka dokümanı ${brandSnap.exists ? 'var' : 'oluşturulacak'}`);
    yeni.forEach((y) => console.log(`   + ${y.ref.path}`));
    mevcut.forEach((m) => console.log(`   = ${m.ref.path} (atlandı)`));

    isler.push({ brand, brandRef, brandVar: brandSnap.exists, yeni });
  }

  if (hata) {
    console.error('\nDoğrulama hataları var, hiçbir şey yazılmadı.');
    process.exit(1);
  }
  if (!yaz) {
    console.log('\nDeneme bitti. Gerçekten yazmak için aynı komuta --yaz ekle.');
    return;
  }

  let toplam = 0;
  for (const is of isler) {
    if (!is.brandVar) await is.brandRef.set({ ad: is.brand.ad });
    for (let i = 0; i < is.yeni.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      is.yeni.slice(i, i + BATCH_LIMIT).forEach((y) => batch.set(y.ref, y.data));
      await batch.commit();
    }
    toplam += is.yeni.length;
  }
  console.log(`\nBitti: ${toplam} doküman yazıldı.`);
}

main().catch((e) => {
  console.error('Hata:', e.message);
  process.exit(1);
});
