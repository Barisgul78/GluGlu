import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Veri modelleri
// ─────────────────────────────────────────────────────────────────────────────

class _GuideItem {
  final String id; // Firestore'daki konu_id ile eşleşir
  final String name;
  final String subtitle;
  final Color iconBg;
  final IconData icon;

  const _GuideItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconBg,
    required this.icon,
  });
}

class _GuideGroup {
  final String title;
  final List<_GuideItem> items;
  const _GuideGroup(this.title, this.items);
}

const _groups = [
  _GuideGroup('BAŞLANGIÇ', [
    _GuideItem(
      id: 'colyak-nedir',
      name: 'Çölyak Nedir?',
      subtitle: 'Belirtiler, tanı, kimlerde görülür',
      iconBg: kPastelGreen,
      icon: Icons.info_outline_rounded,
    ),
    _GuideItem(
      id: 'yeni-tani',
      name: 'Yeni Tanı Aldım',
      subtitle: 'İlk hafta, doktor, ilk alışveriş',
      iconBg: kPastelBlue,
      icon: Icons.assignment_turned_in_outlined,
    ),
    _GuideItem(
      id: 'gluten-nerede-sakli',
      name: 'Gluten Nerede Saklı?',
      subtitle: 'Tahıllar ve gizli kaynaklar',
      iconBg: kPastelYellow,
      icon: Icons.grain_rounded,
    ),
  ]),
  _GuideGroup('GÜNLÜK YAŞAM', [
    _GuideItem(
      id: 'mutfak-capraz-bulasma',
      name: 'Mutfak ve Çapraz Bulaşma',
      subtitle: 'Ayrı ekipman, güvenli hazırlık',
      iconBg: kPastelRed,
      icon: Icons.kitchen_outlined,
    ),
    _GuideItem(
      id: 'etiket-okuma',
      name: 'Etiket Okuma',
      subtitle: 'Glutensiz ibaresi, E kodları',
      iconBg: kPastelGray,
      icon: Icons.label_outlined,
    ),
    _GuideItem(
      id: 'alisveris',
      name: 'Alışveriş Rehberi',
      subtitle: 'Market, marka, hazır ürünler',
      iconBg: kPastelYellow,
      icon: Icons.shopping_cart_outlined,
    ),
    _GuideItem(
      id: 'disarida-yemek-seyahat',
      name: 'Dışarıda Yemek ve Seyahat',
      subtitle: 'Restoran, otel, yurt dışı',
      iconBg: kPastelBlue,
      icon: Icons.flight_takeoff_rounded,
    ),
    _GuideItem(
      id: 'glutensiz-tarifler',
      name: 'Glutensiz Tarifler',
      subtitle: 'Pratik, evde yapılabilen',
      iconBg: kPastelOrange,
      icon: Icons.restaurant_menu_rounded,
    ),
  ]),
  _GuideGroup('AİLE VE ÖZEL DURUMLAR', [
    _GuideItem(
      id: 'cocuklarda-colyak',
      name: 'Çocuklarda Çölyak',
      subtitle: 'Ebeveyn rehberi, okul, kreş',
      iconBg: kPastelPink,
      icon: Icons.child_care_rounded,
    ),
    _GuideItem(
      id: 'hamilelik-emzirme',
      name: 'Hamilelik ve Emzirme',
      subtitle: 'Beslenme ve dikkat edilecekler',
      iconBg: kPastelPink,
      icon: Icons.pregnant_woman_rounded,
    ),
  ]),
  _GuideGroup('SAĞLIK VE DESTEK', [
    _GuideItem(
      id: 'beslenme-eksiklikler',
      name: 'Beslenme ve Eksiklikler',
      subtitle: 'Demir, B12, kalsiyum, D vitamini',
      iconBg: kPastelGreen,
      icon: Icons.medication_outlined,
    ),
    _GuideItem(
      id: 'haklar-destekler',
      name: 'Haklar ve Destekler',
      subtitle: 'Sağlık raporu, SGK, belediye',
      iconBg: kPastelGreen,
      icon: Icons.account_balance_rounded,
    ),
  ]),
];

// ─────────────────────────────────────────────────────────────────────────────
// Rehber Ekranı
// ─────────────────────────────────────────────────────────────────────────────

class RehberScreen extends StatefulWidget {
  const RehberScreen({super.key});

  @override
  State<RehberScreen> createState() => _RehberScreenState();
}

class _RehberScreenState extends State<RehberScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_GuideGroup> get _filtered {
    if (_query.isEmpty) return _groups;
    final q = _query.toLowerCase();
    return _groups
        .map((g) => _GuideGroup(
              g.title,
              g.items
                  .where((i) =>
                      i.name.toLowerCase().contains(q) ||
                      i.subtitle.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((g) => g.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: AppSizes.screenPaddingH,
        title: Text(
          'Rehber',
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontSize: AppSizes.fontXxl,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
              vertical: AppSizes.sm,
            ),
            child: _buildSearchBar(),
          ),
          // Gruplu liste
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: AppSizes.screenPaddingH,
                      right: AppSizes.screenPaddingH,
                      bottom: AppSizes.xxl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildGroup(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: kSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: kOnSurfaceVariant, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Konularda ara...',
                hintStyle: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: const Icon(Icons.close_rounded,
                  color: kOnSurfaceVariant, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildGroup(_GuideGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.lg),
        Text(
          group.title,
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontSize: AppSizes.fontXs + 1,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ...group.items.map((item) => _buildItem(item)),
      ],
    );
  }

  Widget _buildItem(_GuideItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs + 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: kOnSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            onTap: () => context.push('/tips',
                extra: {'topicId': item.id, 'title': item.name}),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  // İkon kutusu
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusSm + 4),
                    ),
                    child: Icon(item.icon,
                        color: kOnSurfaceVariant, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSizes.sm + 4),
                  // İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.manrope(
                            color: kOnSurface,
                            fontSize: AppSizes.fontLg - 1,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.xs - 1),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.manrope(
                            color: kOnSurfaceVariant,
                            fontSize: AppSizes.fontXs + 2,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  const Icon(Icons.chevron_right_rounded,
                      color: kOutlineVariant, size: AppSizes.iconMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              color: kOutlineVariant, size: 48),
          const SizedBox(height: AppSizes.sm),
          Text(
            '"$_query" için sonuç bulunamadı',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
