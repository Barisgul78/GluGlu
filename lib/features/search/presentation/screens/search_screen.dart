import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product.dart';
import '../../data/services/search_service.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../favorites/data/services/favorites_service.dart';
import '../../../profile/data/services/stats_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../../../core/widgets/safe_network_image.dart';
import '../widgets/product_status_badge.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> recentSearches = [];
  static const _allCategory = 'Tümü';
  String selectedCategory = _allCategory;
  Future<List<Product>>? _popularProductsFuture;

  List<Product> _searchResults = [];
  bool _searchLoading = false;
  Object? _searchError;
  Timer? _debounce;
  int _searchRequestId = 0;

  // Favori kalbi için canlı kimlik kümesi; detay/Favoriler'deki değişiklik de yansır.
  Set<String> _favoriteIds = {};
  StreamSubscription? _favoritesSub;

  // Çipler Firestore'daki ürünlerin `kategori` alanından gelir ('Tümü' hariç).
  List<String> _categories = [];
  bool _categoriesLoading = true;
  bool _categoriesError = false;

  bool get _hasActiveSearch =>
      query.isNotEmpty || selectedCategory != _allCategory;

  @override
  void initState() {
    super.initState();
    _popularProductsFuture = SearchService.fetchFeatured();
    _loadCategories();
    _loadRecentSearches();
    _listenFavorites();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      query = widget.initialQuery!.trim().toLowerCase();
      _startNewSearch(query);
    }
  }

  void _listenFavorites() {
    final userId = AuthService.currentUserId;
    if (userId == null) return;
    _favoritesSub = FavoritesService.favoritesStream(userId).listen(
      (snap) {
        if (!mounted) return;
        final ids = (snap.data() as Map?)?['urun_idleri'] ?? [];
        setState(() => _favoriteIds = Set<String>.from(ids));
      },
      onError: (Object e) => debugPrint('Favori akışı hatası: $e'),
    );
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = false;
    });
    try {
      final categories = await SearchService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (e) {
      debugPrint('Kategori yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        _categoriesError = true;
        _categoriesLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    if (category == selectedCategory) return;
    _debounce?.cancel();
    setState(() => selectedCategory = category);
    if (category == _allCategory && query.isEmpty) {
      // Filtre ve yazı yok: ana görünüme dön, bekleyen aramanın cevabını yok say.
      _searchRequestId++;
      setState(() {
        _searchResults = [];
        _searchError = null;
        _searchLoading = false;
      });
      return;
    }
    _startNewSearch(query);
  }

  Future<void> _startNewSearch(String q) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _searchResults = [];
      _searchError = null;
      _searchLoading = true;
    });
    try {
      final results = await SearchService.searchByName(
        q,
        category: selectedCategory == _allCategory ? null : selectedCategory,
      );
      // Beklerken yeni bir arama başlamışsa bu cevap eski (stale) demektir, yok say.
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = results;
        _searchLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchError = e;
        _searchLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    final q = value.trim();
    // Bekleyen/eski aramanın geç gelen cevabı yeni yazıyı bozmasın.
    _searchRequestId++;
    // Debounce beklerken de yükleniyor göster; yoksa 500 ms "bulunamadı" yazısı çıkar.
    setState(() {
      query = q.toLowerCase();
      _searchLoading = _hasActiveSearch;
    });
    _debounce?.cancel();
    if (q.isEmpty) {
      if (selectedCategory != _allCategory) {
        // Yazı silindi ama kategori seçili: kategorinin tüm ürünleri kalsın.
        _startNewSearch('');
        return;
      }
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _startNewSearch(q);
    });
  }

  void _retrySearch() {
    _startNewSearch(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleFavoriteFromSearch(Product product) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorilere eklemek için giriş yapmanız gerekiyor.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final wasFavorite = _favoriteIds.contains(product.id);
    try {
      await FavoritesService.toggleProductFavorite(product.id,
          isFavorite: wasFavorite);
    } catch (e) {
      debugPrint('Favori güncellenemedi: $e');
      if (mounted) {
        showErrorSnackBar(context, 'Favori güncellenemedi. Lütfen tekrar deneyin.');
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasFavorite
              ? '${product.name} favorilerden çıkarıldı.'
              : '${product.name} favorilere eklendi!'),
          duration: const Duration(seconds: 1),
          backgroundColor: kPrimary,
        ),
      );
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        recentSearches = prefs.getStringList('recentSearches') ?? [];
      });
    }
  }

  Future<void> _saveSearch(String productName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.remove(productName);
      recentSearches.insert(0, productName);
      if (recentSearches.length > 5) recentSearches.removeLast();
    });
    await prefs.setStringList('recentSearches', recentSearches);
  }

  void _onSearchSubmitted(String value) {
    final userId = AuthService.currentUserId;
    if (userId != null && value.trim().isNotEmpty) {
      StatsService.incrementSearchCount(userId);
    }
  }

  Future<void> _clearSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentSearches');
    setState(() => recentSearches.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasActiveSearch) _buildLiveSearchList(),
                    if (!_hasActiveSearch) ...[
                      if (recentSearches.isNotEmpty) _buildRecentSearches(),
                      _buildPopularSection(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ürün Ara',
                  style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Güvenilir glutensiz ürünleri keşfedin',
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kOutlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kOnSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                onChanged: _onQueryChanged,
                onSubmitted: _onSearchSubmitted,
                decoration: InputDecoration(
                  hintText: 'Ürün, marka veya kategori...',
                  hintStyle: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final cat in [_allCategory, ..._categories])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _categoryChip(cat),
            ),
          if (_categoriesLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
              ),
            ),
          if (_categoriesError)
            GestureDetector(
              onTap: _loadCategories,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kOutlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: kPrimary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Kategoriler yüklenemedi, tekrar dene',
                      style: GoogleFonts.manrope(
                        color: kPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(String cat) {
    final isSelected = selectedCategory == cat;
    return GestureDetector(
      onTap: () => _onCategorySelected(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kPrimary : kOutlineVariant),
        ),
        child: Center(
          child: Text(
            cat,
            style: GoogleFonts.manrope(
              color: isSelected ? kOnPrimary : kOnSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Aramalar',
                style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              GestureDetector(
                onTap: _clearSearches,
                child: Text('Temizle',
                    style: GoogleFonts.manrope(
                        color: kPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: recentSearches.map(_recentSearchTag).toList()),
          ),
        ],
      ),
    );
  }

  Widget _recentSearchTag(String text) {
    return GestureDetector(
      onTap: () {
        _debounce?.cancel();
        _searchController.text = text;
        query = text.toLowerCase();
        _startNewSearch(query);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kOutlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.history, color: kOnSurfaceVariant, size: 14),
            const SizedBox(width: 6),
            Text(text,
                style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popüler Ürünler',
            style: GoogleFonts.manrope(
                color: kOnSurface, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Product>>(
            future: _popularProductsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                );
              }
              final products = snap.data ?? [];
              if (products.isEmpty) {
                return Text(
                  'Henüz ürün eklenmemiş.',
                  style: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                );
              }
              return Column(
                children: products.map((product) {
                  return GestureDetector(
                    onTap: () => context.push('/urun', extra: product),
                    child: _popularCard(
                      name: product.name,
                      brand: product.brand,
                      category: product.category,
                      status: product.status,
                      imageUrl: product.imageUrl,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _popularCard({
    required String name,
    required String brand,
    required String category,
    required ProductStatus status,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOutlineVariant),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeNetworkImage(
                  imageUrl: imageUrl,
                  width: 80,
                  height: 80,
                  fallbackIcon: Icons.fastfood,
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: ProductStatusBadge(
                  status: status,
                  borderRadius: 5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.toUpperCase(),
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    color: kOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kOutlineVariant, size: 20),
        ],
      ),
    );
  }

  Widget _buildLiveSearchList() {
    if (_searchLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: kPrimary),
        ),
      );
    }

    if (_searchError != null) {
      debugPrint('Ürün yükleme hatası: $_searchError');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ürünler yüklenirken bir hata oluştu.',
              style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retrySearch,
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tekrar Dene',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final results = _searchResults;

    if (results.isEmpty) {
      final hasCategory = selectedCategory != _allCategory;
      final emptyText = query.isEmpty
          ? '"$selectedCategory" kategorisinde ürün bulunamadı.'
          : hasCategory
              ? '"$query" ile "$selectedCategory" kategorisinde eşleşen ürün bulunamadı.'
              : '"$query" ile eşleşen ürün bulunamadı.';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Text(
          emptyText,
          style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            '${results.length} sonuç',
            style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: results.length,
          itemBuilder: (context, index) =>
              _buildSearchResultCard(context, results[index]),
        ),
      ],
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        _saveSearch(product.name);
        context.push('/urun', extra: product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kOnPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kOnSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SafeNetworkImage(
                    imageUrl: product.imageUrl,
                    width: 72,
                    height: 72,
                    fallbackIcon: Icons.fastfood,
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: ProductStatusBadge(
                    status: product.status,
                    borderRadius: 5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: GoogleFonts.manrope(
                      color: kOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category,
                    style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavoriteFromSearch(product),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  _favoriteIds.contains(product.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: kSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
