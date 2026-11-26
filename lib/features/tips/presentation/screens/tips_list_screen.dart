import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/utils/date_utils.dart' as du;
import '../../data/models/tip.dart';
import '../../data/services/rehber_service.dart';
import '../../data/services/tips_service.dart';
import '../widgets/category_badge.dart';
import '../widgets/tip_image.dart';

// topicId verilirse Rehber konusunun bilgi kartlarını (Firestore) listeler;
// verilmezse Günün Bilgisi listesini gösterir.
class TipsListScreen extends StatefulWidget {
  final String? topicId;
  final String? title;

  const TipsListScreen({super.key, this.topicId, this.title});

  @override
  State<TipsListScreen> createState() => _TipsListScreenState();
}

class _TipsListScreenState extends State<TipsListScreen> {
  List<Tip> _tips = const [];
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    if (widget.topicId == null) {
      _tips = TipsService.getAll();
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final tips = await RehberService.fetchByTopic(widget.topicId!);
      if (!mounted) return;
      setState(() => _tips = tips);
    } catch (e) {
      debugPrint('Rehber bilgileri yüklenemedi: $e');
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kOnSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title ?? 'Günün Bilgisi',
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontSize: AppSizes.fontXl,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_error) {
      return _buildMessage(
        'Bilgiler yüklenemedi.\nBağlantınızı kontrol edip tekrar deneyin.',
        retry: true,
      );
    }
    if (_tips.isEmpty) {
      return _buildMessage('Bu başlıktaki bilgiler yakında eklenecek.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPaddingH,
        vertical: AppSizes.md,
      ),
      itemCount: _tips.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, i) => _TipListCard(
        tip: _tips[i],
        formattedDate: du.formatDate(_tips[i].date),
        onTap: () => context.push('/tips/detay', extra: _tips[i]),
      ),
    );
  }

  Widget _buildMessage(String message, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.fontMd,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (retry) ...[
              const SizedBox(height: AppSizes.space12),
              TextButton(
                onPressed: _load,
                child: Text(
                  'Tekrar dene',
                  style: GoogleFonts.manrope(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liste öğesi kartı
// ─────────────────────────────────────────────────────────────────────────────
class _TipListCard extends StatelessWidget {
  const _TipListCard({
    required this.tip,
    required this.formattedDate,
    required this.onTap,
  });

  final Tip tip;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppSizes.radiusLg),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: TipImage(asset: tip.imageAsset),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryBadge(
                      label: tip.category,
                      filled: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 3,
                      ),
                      fontSize: AppSizes.fontXs + 1,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      tip.title,
                      style: GoogleFonts.manrope(
                        color: kOnSurface,
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      formattedDate,
                      style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: AppSizes.fontXs + 1,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.sm),
              child: Icon(Icons.chevron_right_rounded,
                  color: kOnSurfaceVariant, size: AppSizes.iconMd),
            ),
          ],
        ),
      ),
    );
  }
}
