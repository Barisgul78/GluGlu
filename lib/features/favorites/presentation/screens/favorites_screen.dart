import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../search/data/models/product.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/favorites_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../tips/data/models/tip.dart';
import '../../../tips/data/services/tips_service.dart';
import '../../../tips/presentation/widgets/category_badge.dart';
import '../../../tips/presentation/widgets/tip_image.dart';
import '../../../../../core/utils/date_utils.dart' as du;
import '../../../../core/constants/app_sizes.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String selectedTab = 'Ürünler';
  final TextEditingController _searchController = TextEditingController();

  // Ürün listesi yalnızca favori kimlikleri değişince yeniden okunur;
  // eski cevabı reddetmek için artan istek numarası (search_screen deseni).
  List<String>? _loadedIds;
  List<Product> _products = const [];
  bool _productsLoading = false;
  bool _productsError = false;
  int _productsRequestId = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // StreamBuilder içinden çağrılır; ilk senkron kısımda setState yoktur.
  Future<void> _loadProducts(List<String> ids) async {
    final requestId = ++_productsRequestId;
    _loadedIds = ids;
    _productsLoading = true;
    _productsError = false;
    try {
      final products = await FavoritesService.fetchProductsByIds(ids);
      if (!mounted || requestId != _productsRequestId) return;
      if (products.length < ids.length) {
        final found = products.map((p) => p.id).toSet();
        debugPrint(
            'Bulunamayan favori ürün kimlikleri: ${ids.where((id) => !found.contains(id)).toList()}');
      }
      setState(() {
        _products = products;
        _productsLoading = false;
      });
    } catch (e) {
      debugPrint('Favori ürünler yüklenemedi: $e');
      if (!mounted || requestId != _productsRequestId) return;
      setState(() {
        _productsError = true;
        _productsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSwitcher(),
            const SizedBox(height: AppSizes.space12),
            Expanded(
              child: selectedTab == 'Ürünler'
                  ? _buildProductsList()
                  : selectedTab == 'Mekanlar'
                      ? _buildVenuesList()
                      : _buildArticlesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.space20, AppSizes.md, AppSizes.space20, AppSizes.space12),
      child: Row(
        children: [
          const Spacer(),
          Text(
            'Favoriler',
            style: GoogleFonts.manrope(
              color: kOnSurface,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontXl,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSizes.radius30),
          border: Border.all(color: kOutlineVariant),
        ),
        child: Row(
          children: [
            Expanded(child: _tabButton('Ürünler')),
            Expanded(child: _tabButton('Mekanlar')),
            Expanded(child: _tabButton('Makaleler')),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String title) {
    final isSelected = selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.space10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: isSelected ? kOnPrimary : kOnSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.fontMd,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text(
            'Favorilerinizi görmek için\ngiriş yapmanız gerekiyor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: FavoritesService.favoritesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimary));
        }

        final data = snapshot.data;
        final List<String> productIds = (data != null && data.exists)
            ? List<String>.from((data.data() as Map?)?['urun_idleri'] ?? [])
            : [];

        if (productIds.isEmpty) {
          return Center(
            child: Text(
              'Henüz favori ürün eklemediniz.',
              style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600),
            ),
          );
        }

        if (!listEquals(_loadedIds, productIds)) _loadProducts(productIds);

        if (_productsLoading) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }

        if (_productsError) return _buildProductsError();

        if (_products.isEmpty) {
          return Center(
            child: Text(
              'Favori ürünleriniz bulunamadı.',
              style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
          itemCount: _products.length,
          itemBuilder: (context, index) => _buildProductCard(_products[index]),
        );
      },
    );
  }

  Widget _buildProductsError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ürünler yüklenemedi.\nBağlantınızı kontrol edip tekrar deneyin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.space12),
            TextButton(
              // _loadedIds sıfırlanınca bir sonraki build ürünleri yeniden yükler.
              onPressed: () => setState(() => _loadedIds = null),
              child: Text(
                'Tekrar dene',
                style: GoogleFonts.manrope(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, color: kOutlineVariant, size: 52),
            const SizedBox(height: AppSizes.md),
            Text(
              'Favori mekan bulunamadı',
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontLg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Mekanlar sekmesinden beğendiğiniz mekanlarda kalp ikonuna basarak favorilerinize ekleyebilirsiniz.',
              style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.font13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Text(
            'Favorilerinizi görmek için\ngiriş yapmanız gerekiyor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return StreamBuilder(
      stream: FavoritesService.favoritesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kPrimary));
        }

        final data = snapshot.data;
        final List<String> tipIds = (data != null && data.exists)
            ? List<String>.from((data.data() as Map?)?['makale_idleri'] ?? [])
            : [];

        if (tipIds.isEmpty) {
          return Center(
            child: Text(
              'Kayıtlı makale bulunamadı.',
              style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600),
            ),
          );
        }

        final tips =
            TipsService.getAll().where((t) => tipIds.contains(t.id)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
          itemCount: tips.length,
          itemBuilder: (context, index) => _buildArticleCard(tips[index]),
        );
      },
    );
  }

  Widget _buildArticleCard(Tip tip) {
    return GestureDetector(
      onTap: () => context.push('/tips/detay', extra: tip),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space12),
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: kOutlineVariant),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: TipImage(asset: tip.imageAsset),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: CategoryBadge(
                    label: tip.category,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.space6, vertical: AppSizes.space2),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSizes.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.author.toUpperCase(),
                    style: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontSize: AppSizes.fontXs,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space2),
                  Text(
                    tip.title,
                    style: GoogleFonts.manrope(
                      color: kOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    du.formatDate(tip.date),
                    style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await FavoritesService.toggleArticleFavorite(tip.id,
                    isFavorite: true);
              },
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.space6),
                child:
                    Icon(Icons.bookmark_rounded, color: kSecondary, size: AppSizes.icon20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => context.push('/urun', extra: product),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.space12),
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: kOutlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: SafeNetworkImage(
                imageUrl: product.imageUrl,
                width: 72,
                height: 72,
                fallbackIcon: Icons.fastfood,
              ),
            ),
            const SizedBox(width: AppSizes.space14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.manrope(
                      color: kOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.space2),
                  Text(
                    product.brand,
                    style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.space6),
                  _statusBadge(product.status),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            const Icon(Icons.favorite, color: kSecondary, size: AppSizes.icon22),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ProductStatus status) {
    final Color bg;
    final Color fg;
    final String text;
    switch (status) {
      case ProductStatus.safe:
        bg = kPrimaryFixed;
        fg = kPrimary;
        text = 'Glutensiz';
      case ProductStatus.risky:
        bg = kErrorContainer;
        fg = kOnErrorContainer;
        text = 'Riskli';
      case ProductStatus.unknown:
        bg = kSurfaceContainerHigh;
        fg = kOnSurfaceVariant;
        text = 'Bilinmiyor';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
