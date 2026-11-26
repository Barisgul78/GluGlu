import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/widgets/bubble_background.dart';
import '../../data/models/tip.dart';
import '../widgets/category_badge.dart';
import '../widgets/tip_image.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../favorites/data/services/favorites_service.dart';
import '../../../profile/data/services/stats_service.dart';

class TipDetailScreen extends StatefulWidget {
  final Tip tip;

  const TipDetailScreen({super.key, required this.tip});

  @override
  State<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<TipDetailScreen> {
  bool _saved = false;
  bool _readRegistered = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Rehber bilgileri Firestore'dan geliyor; kaydetme yalnızca Günün Bilgisi'nde
    if (widget.tip.topicId == null) _checkIfSaved();
    _scrollController.addListener(_maybeRegisterRead);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRegisterRead());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Kısa içerikte scroll hiç mümkün değilse direkt okundu say; değilse
  // sayfa sonuna (uyarı notu/kaydet satırı) yaklaşınca say.
  void _maybeRegisterRead() {
    if (_readRegistered) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final scrollable = position.maxScrollExtent > 0;
    if (!scrollable || position.pixels >= position.maxScrollExtent - 24) {
      _readRegistered = true;
      final userId = AuthService.currentUserId;
      if (userId != null) {
        StatsService.registerArticleRead(userId, widget.tip.id);
      }
    }
  }

  Future<void> _checkIfSaved() async {
    final saved = await FavoritesService.isArticleFavorite(widget.tip.id);
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _toggleSaved() async {
    if (AuthService.currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kaydetmek için giriş yapmanız gerekiyor.')),
        );
      }
      return;
    }
    await FavoritesService.toggleArticleFavorite(widget.tip.id, isFavorite: _saved);
    if (mounted) setState(() => _saved = !_saved);
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kOnSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Günün Bilgisi',
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const BubbleBackground(),
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
              vertical: AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroImage(tip),
                const SizedBox(height: AppSizes.lg),
                _buildTitle(tip),
                const SizedBox(height: AppSizes.lg),
                ..._buildSections(tip),
                const Divider(height: AppSizes.xl, color: kOutlineVariant),
                _buildFooter(tip),
                const SizedBox(height: AppSizes.xxl + AppSizes.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(Tip tip) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: TipImage(asset: tip.imageAsset, iconSize: 40),
          ),
        ),
        Positioned(
          top: AppSizes.sm + 4,
          left: AppSizes.sm + 4,
          child: CategoryBadge(label: tip.category),
        ),
      ],
    );
  }

  Widget _buildTitle(Tip tip) {
    return Text(
      tip.title,
      style: GoogleFonts.manrope(
        color: kOnSurface,
        fontSize: AppSizes.fontXxl - 2,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.3,
      ),
    );
  }

  List<Widget> _buildSections(Tip tip) {
    final widgets = <Widget>[];

    // Özet paragraf
    widgets.add(
      Text(
        tip.summary,
        style: GoogleFonts.manrope(
          color: kOnSurfaceVariant,
          fontSize: AppSizes.fontLg - 1,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
      ),
    );
    widgets.add(const SizedBox(height: AppSizes.lg));

    for (final section in tip.sections) {
      widgets.add(
        Text(
          section.heading,
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontSize: AppSizes.fontXl - 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      widgets.add(const SizedBox(height: AppSizes.xs + 2));
      widgets.add(
        Text(
          section.body,
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontSize: AppSizes.fontLg - 1,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      );
      widgets.add(const SizedBox(height: AppSizes.lg));
    }

    return widgets;
  }

  Widget _buildFooter(Tip tip) {
    final warning = Text(
      'Bilgilendirme amaçlıdır. Tanı ve tedavi için doktorunuza danışın.',
      style: GoogleFonts.manrope(
        color: kOnSurfaceVariant,
        fontSize: AppSizes.fontSm + 1,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
    );

    // Rehber bilgilerinde kaydet düğmesi yok (Favoriler entegrasyonu sonraki iş)
    if (tip.topicId != null) return warning;

    return Row(
      children: [
        Expanded(child: warning),
        const SizedBox(width: AppSizes.md),
        GestureDetector(
          onTap: _toggleSaved,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary, width: 1.5),
            ),
            child: Icon(
              _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _saved ? kSecondary : kOnSurfaceVariant,
              size: AppSizes.iconSm + 4,
            ),
          ),
        ),
      ],
    );
  }
}