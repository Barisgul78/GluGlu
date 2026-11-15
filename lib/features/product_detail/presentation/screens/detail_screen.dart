import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../search/data/models/product.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../favorites/data/services/favorites_service.dart';
import '../../../profile/data/services/stats_service.dart';
import '../../../tips/presentation/widgets/category_badge.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/safe_network_image.dart';

// Modelin eksik-alan varsayılanı; gerçek kategori sayılmaz, gösterilmez.
const _kDefaultCategory = 'Genel';

// Besin satırları: (besin_degerleri anahtarı, etiket, birim). Sıra ekrandaki sıradır.
// Enerji kcal/kJ birlikte gösterildiği için ayrıca işlenir.
const _nutritionRows = <(String, String, String)>[
  ('protein', 'Protein', 'g'),
  ('karbonhidrat', 'Karbonhidrat', 'g'),
  ('seker', 'Şeker', 'g'),
  ('yag', 'Yağ', 'g'),
  ('doymus_yag', 'Doymuş yağ', 'g'),
  ('trans_yag', 'Trans yağ', 'g'),
  ('tuz', 'Tuz', 'g'),
  ('kalsiyum', 'Kalsiyum', 'mg'),
  ('fosfor', 'Fosfor', 'mg'),
  ('d_vitamini', 'D vitamini', 'µg'),
];

class DetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;

  const DetailScreen({super.key, required this.product, required this.onBack});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  bool _favBusy = false;

  Product get _p => widget.product;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    final userId = AuthService.currentUserId;
    if (userId != null) {
      StatsService.registerProductClicked(userId, _p.id);
    }
  }

  Future<void> _checkIfFavorite() async {
    final isF = await FavoritesService.isProductFavorite(_p.id);
    if (mounted) setState(() => _isFavorite = isF);
  }

  Future<void> _toggleFavorite() async {
    if (AuthService.currentUserId == null) {
      showInfoSnackBar(context, 'Favorilere eklemek için giriş yapmanız gerekiyor.');
      return;
    }
    setState(() => _favBusy = true);
    try {
      await FavoritesService.toggleProductFavorite(_p.id, isFavorite: _isFavorite);
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      debugPrint('Favori güncellenemedi: $e');
      if (mounted) {
        showErrorSnackBar(context, 'Favori güncellenemedi. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  Future<void> _share() async {
    final title = [_p.name, _p.brand].where((s) => s.isNotEmpty).join(' • ');
    final status = switch (_p.status) {
      ProductStatus.safe => 'Gluten durumu: Güvenli',
      ProductStatus.risky => 'Gluten durumu: Riskli',
      ProductStatus.unknown => 'Gluten durumu: Bilinmiyor',
    };
    try {
      await SharePlus.instance.share(
        ShareParams(text: '$title\n$status\nGluGlu ile keşfettim.'),
      );
    } catch (e) {
      debugPrint('Paylaşım açılamadı: $e');
      if (mounted) {
        showErrorSnackBar(context, 'Paylaşım açılamadı. Lütfen tekrar deneyin.');
      }
    }
  }

  // Türkçe büyük harf: i → İ, ı → I (toUpperCase bunu yapmaz).
  String _trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final infoRows = _infoRows();
    final nutrition = _nutritionEntries();
    final ingredients = _p.ingredients?.trim() ?? '';

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPaddingH,
                      AppSizes.sm,
                      AppSizes.screenPaddingH,
                      AppSizes.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageCard(),
                        const SizedBox(height: AppSizes.md),
                        _buildBrandRow(),
                        const SizedBox(height: AppSizes.sm),
                        _buildTitle(),
                        const SizedBox(height: AppSizes.lg),
                        _buildGlutenCard(),
                        if (infoRows.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.lg),
                          _sectionTitle('Ürün bilgileri'),
                          _infoCard(infoRows),
                        ],
                        if (nutrition.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.lg),
                          _sectionTitle('Besin değerleri (100 g)'),
                          _infoCard(nutrition),
                        ],
                        if (ingredients.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.lg),
                          _sectionTitle('İçindekiler'),
                          _ingredientsCard(ingredients),
                        ],
                        const SizedBox(height: AppSizes.lg),
                        _buildDisclaimer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: kBackground,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: kOnSurface, size: 20),
        onPressed: widget.onBack,
      ),
      title: Text(
        'Ürün detayı',
        style: GoogleFonts.manrope(
          color: kOnSurface,
          fontWeight: FontWeight.w700,
          fontSize: AppSizes.fontXl,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share, color: kOnSurface, size: 22),
          tooltip: 'Paylaş',
          onPressed: _share,
        ),
      ],
    );
  }

  Widget _buildImageCard() {
    final hasImage = _p.imageUrl.startsWith('http://') || _p.imageUrl.startsWith('https://');

    return Container(
      width: double.infinity,
      height: AppSizes.heroBannerHeight,
      decoration: BoxDecoration(
        color: kSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? SafeNetworkImage(
              imageUrl: _p.imageUrl,
              height: AppSizes.heroBannerHeight,
              fit: BoxFit.contain,
              fallbackIcon: Icons.inventory_2_outlined,
              fallbackIconColor: kPrimary,
              fallbackIconSize: AppSizes.xxl,
              fallbackBackgroundColor: kSurfaceContainerHigh,
            )
          : _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.xxl * 2,
            height: AppSizes.xxl * 2,
            decoration: BoxDecoration(
              color: kSurface.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, color: kPrimary, size: AppSizes.iconLg + AppSizes.sm),
          ),
          const SizedBox(height: AppSizes.sm + 4),
          Text(
            'Ürün görseli bulunmuyor',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandRow() {
    final hasCategory = _p.category.isNotEmpty && _p.category != _kDefaultCategory;

    // İki flex çocuk boş alanı eşit paylaşır; Expanded kullanılırsa çip ortadan başlar.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            _trUpper(_p.brand),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ),
        if (hasCategory) ...[
          const SizedBox(width: AppSizes.sm),
          Flexible(child: CategoryBadge(label: _p.category, filled: false)),
        ],
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      _p.name,
      style: GoogleFonts.manrope(
        color: kPrimary,
        fontSize: AppSizes.fontDisplay,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
    );
  }

  Widget _buildGlutenCard() {
    final style = _statusStyle(_p.status);
    // Veri "Marka Beyanı: ..." önekiyle gelir; başlık ayrıca yazıldığı için önek kırpılır.
    final proof = (_p.kanitCumlesi ?? '')
        .trim()
        .replaceFirst(RegExp(r'^Marka Beyanı\s*:\s*', caseSensitive: false), '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md + 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.xxl,
                height: AppSizes.xxl,
                decoration: BoxDecoration(
                  color: style.iconBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd + 2),
                ),
                child: Icon(style.icon, color: Colors.white, size: AppSizes.iconMd),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gluten durumu',
                      style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      style.label,
                      style: GoogleFonts.manrope(
                        color: style.labelColor,
                        fontSize: AppSizes.fontXxl,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (proof.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            Divider(height: 1, color: style.border),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const Icon(Icons.description_outlined, color: kOnSurfaceVariant, size: AppSizes.iconSm),
                const SizedBox(width: AppSizes.sm - 2),
                Text(
                  'Marka Beyanı',
                  style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              proof,
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontSize: AppSizes.fontLg,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(ProductStatus status) {
    switch (status) {
      case ProductStatus.safe:
        return _StatusStyle(
          label: 'Güvenli',
          icon: Icons.verified_user_outlined,
          background: kPastelGreen,
          border: kPrimary.withValues(alpha: 0.18),
          iconBackground: kPrimary,
          labelColor: kPrimary,
        );
      case ProductStatus.risky:
        return _StatusStyle(
          label: 'Riskli',
          icon: Icons.warning_amber_rounded,
          background: kErrorContainer,
          border: kError.withValues(alpha: 0.25),
          iconBackground: kError,
          labelColor: kOnErrorContainer,
        );
      case ProductStatus.unknown:
        return const _StatusStyle(
          label: 'Bilinmiyor',
          icon: Icons.help_outline,
          background: kSurfaceContainerHigh,
          border: kOutlineVariant,
          iconBackground: kOutline,
          labelColor: kOnSurfaceVariant,
        );
    }
  }

  List<(String, String)> _infoRows() {
    return [
      if (_p.brand.isNotEmpty) ('Marka', _p.brand),
      if (_p.category.isNotEmpty && _p.category != _kDefaultCategory) ('Kategori', _p.category),
    ];
  }

  List<(String, String)> _nutritionEntries() {
    final n = _p.nutrition;
    final entries = <(String, String)>[];

    final kcal = n['enerji_kcal'];
    final kj = n['enerji_kj'];
    if (kcal != null || kj != null) {
      final text = kcal != null ? '$kcal kcal${kj != null ? ' ($kj kJ)' : ''}' : '$kj kJ';
      entries.add(('Enerji', text));
    }
    for (final (key, label, unit) in _nutritionRows) {
      final value = n[key];
      if (value != null) entries.add((label, '$value $unit'));
    }
    return entries;
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm + 4),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kOnSurface,
          fontSize: AppSizes.fontXl,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration get _whiteCardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: kOnSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _infoCard(List<(String, String)> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, thickness: 1, color: kSurfaceContainerHigh));
      }
      children.add(_infoRow(rows[i].$1, rows[i].$2));
    }
    return Container(
      width: double.infinity,
      decoration: _whiteCardDecoration,
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md - 2),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientsCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: _whiteCardDecoration,
      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: kOnSurfaceVariant,
          fontSize: AppSizes.fontMd,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline, color: kOnSurfaceVariant, size: AppSizes.iconSm),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(
            'Tüketmeden önce ambalajdaki güncel içerik ve alerjen bilgisini kontrol edin.',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.sm,
        AppSizes.screenPaddingH,
        AppSizes.md,
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: _isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          borderRadius: AppSizes.radiusLg,
          loading: _favBusy,
          onPressed: _toggleFavorite,
        ),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final IconData icon;
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color labelColor;

  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.labelColor,
  });
}
