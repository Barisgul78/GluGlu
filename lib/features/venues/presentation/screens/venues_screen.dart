import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../profile/data/services/stats_service.dart';
import '../../data/models/venue.dart';
import '../../data/services/venues_service.dart';
import '../../../../core/constants/app_sizes.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  String selectedFilter = 'Tüm Mekanlar';
  final ScrollController _scrollController = ScrollController();

  List<Venue> _venues = [];
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await VenuesService.fetchPage();
      if (!mounted) return;
      setState(() {
        _venues = page.items;
        _lastDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await VenuesService.fetchPage(startAfter: _lastDoc);
      if (!mounted) return;
      setState(() {
        _venues = [..._venues, ...page.items];
        _lastDoc = page.lastDocument;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('Sonraki mekan sayfası yüklenemedi: $e');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            const SliverPadding(padding: EdgeInsets.only(top: AppSizes.sm)),
            SliverToBoxAdapter(child: _buildVenuesBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_error != null) {
      debugPrint('Mekan yükleme hatası: $_error');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl, vertical: 60),
        child: Column(
          children: [
            Text(
              'Mekanlar yüklenirken bir hata oluştu.',
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.font15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.space12),
            TextButton(
              onPressed: _loadInitial,
              style: TextButton.styleFrom(foregroundColor: kPrimary),
              child: Text(
                'Tekrar Dene',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_venues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl, vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.location_off_outlined,
                color: kOutlineVariant, size: 52),
            const SizedBox(height: AppSizes.md),
            Text(
              'Henüz mekan eklenmemiş',
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontLg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Yakında glutensiz dostu mekanlar burada görünecek.',
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
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
      child: Column(
        children: [
          ..._venues.map((v) => _buildVenueCard(
                venueId: v.id,
                imageUrl: v.imageUrl,
                title: v.title,
                description: v.description,
                rating: v.rating,
                distance: v.distance,
                location: v.location,
                badgeText: v.badgeText,
                badgeColor: kPrimary,
                tags: v.tags,
              )),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.space20),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            ),
          const SizedBox(height: AppSizes.space20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.space20, AppSizes.space20, AppSizes.space20, AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glutensiz Mekanları\nKeşfet',
                  style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSizes.space6),
                Text(
                  'Bütünsel yaşam tarzınıza hitap eden güvenilir yerel mekanları keşfedin.',
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontSize: AppSizes.font13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.space12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kSurfaceContainerHigh,
            ),
            child: const Icon(Icons.notifications_outlined, color: kOnSurfaceVariant, size: AppSizes.icon20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.space20, AppSizes.md, AppSizes.space20, AppSizes.space12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSizes.radius30),
          border: Border.all(color: kOutlineVariant),
        ),
        child: TextField(
          style: const TextStyle(color: kOnSurface),
          decoration: InputDecoration(
            icon: const Icon(Icons.search, color: kOnSurfaceVariant, size: AppSizes.icon20),
            hintText: 'Kafe, fırın veya bölge ara...',
            hintStyle: GoogleFonts.manrope(color: kOnSurfaceVariant, fontSize: AppSizes.fontMd, fontWeight: FontWeight.w600),
            suffixIcon: const Icon(Icons.tune_rounded, color: kOnSurfaceVariant, size: AppSizes.icon20),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Tüm Mekanlar', 'Kafeler & Fırınlar', 'Restoranlar', 'Büfeler'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : kSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSizes.radius20),
                border: Border.all(color: isSelected ? kPrimary : kOutlineVariant),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? kOnPrimary : kOnSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.font13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onVenueExplored(BuildContext context, String venueId) {
    final userId = AuthService.currentUserId;
    if (userId != null) {
      StatsService.registerVenueDiscovered(userId, venueId);
    }
    showInfoSnackBar(context, 'Yakında');
  }

  Widget _buildVenueCard({
    required String venueId,
    required String imageUrl,
    required String title,
    required String description,
    required String rating,
    required String distance,
    required String location,
    required String badgeText,
    required Color badgeColor,
    required List<String> tags,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(AppSizes.radius20),
        border: Border.all(color: kOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Görsel + overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radius20)),
                child: SafeNetworkImage(
                  imageUrl: imageUrl,
                  height: 180,
                  width: double.infinity,
                  fallbackIcon: Icons.restaurant,
                  fallbackIconSize: 40,
                ),
              ),
              // Favori butonu
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kSurface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: kSecondary, size: 18),
                ),
              ),
              // Badge
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.space10, vertical: AppSizes.xs),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(AppSizes.radius20),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          color: kOnSurface,
                          fontSize: AppSizes.font17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: kStar, size: AppSizes.iconSm),
                        const SizedBox(width: AppSizes.space2),
                        Text(
                          rating,
                          style: GoogleFonts.manrope(
                            color: kOnSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.font13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.space6),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontSize: AppSizes.font13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: 6,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space10, vertical: AppSizes.xs),
                      decoration: BoxDecoration(
                        color: kPrimaryFixed,
                        borderRadius: BorderRadius.circular(AppSizes.radius20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: AppSizes.space10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: kOnSurfaceVariant, size: 14),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '$distance • $location',
                      style: GoogleFonts.manrope(color: kOnSurfaceVariant, fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.space12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _onVenueExplored(context, venueId),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: kOnPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.space12),
                        ),
                        child: Text(
                          'Detayları Gör',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kOutlineVariant),
                        color: kSurfaceContainerHigh,
                      ),
                      child: const Icon(Icons.map_outlined, color: kPrimary, size: AppSizes.icon20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
