import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/profile_service.dart';
import 'profile_ui.dart';

const _productBadgeSteps = [50, 100, 150, 200, 300, 400, 500, 750, 1000];

// Kullanıcı dokümanındaki `istatistikler` map'ini verir; misafirde boş map (sayaçlar 0 görünür)
class _StatsBuilder extends StatelessWidget {
  const _StatsBuilder({required this.builder});

  final Widget Function(Map<String, dynamic> stats) builder;

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId;
    if (userId == null) return builder(const {});

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ProfileService.userStream(userId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data?.data()?['istatistikler'] as Map<String, dynamic>? ??
                const {};
        return builder(stats);
      },
    );
  }
}

int _count(Map<String, dynamic> stats, String key) =>
    (stats[key] as List?)?.length ?? 0;

// "Bir sonraki rozete N ürün kaldı" kartı
class NextBadgeCard extends StatelessWidget {
  const NextBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatsBuilder(
      builder: (stats) {
        final incelenen = _count(stats, 'tiklanan_urun_idleri');
        final nextBadge = _productBadgeSteps.firstWhere(
          (s) => s > incelenen,
          orElse: () => _productBadgeSteps.last,
        );
        final kalan = (nextBadge - incelenen).clamp(0, nextBadge);
        final progress = nextBadge == 0 ? 0.0 : incelenen / nextBadge;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kalan > 0
                    ? 'Bir sonraki rozete $kalan ürün kaldı!'
                    : 'Rozet tamamlandı!',
                style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontLg,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                'Keşfetmeye devam et, yeni rozetin yaklaşsın.',
                style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              LinearPercentIndicator(
                lineHeight: 8,
                percent: progress.clamp(0.0, 1.0),
                backgroundColor: kSurfaceContainerHigh,
                progressColor: kPrimary,
                barRadius: const Radius.circular(AppSizes.radiusFull),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSizes.sm + 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$incelenen / $nextBadge ürün incelendi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: kOnSurfaceVariant,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  FilledButton(
                    onPressed: () => context.go('/search'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md + 4,
                          vertical: AppSizes.sm + 4),
                    ),
                    child: Text(
                      'Ürün keşfet →',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.fontSm + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// "Keşif özetim" 3 sütunlu sayaç kartı
class DiscoverySummaryCard extends StatelessWidget {
  const DiscoverySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatsBuilder(
      builder: (stats) {
        final aranan = stats['aranan_urun_toplam'] as int? ?? 0;
        final makale = _count(stats, 'okunan_makale_idleri');
        final mekan = _count(stats, 'kesfedilen_mekan_idleri');

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppSizes.md + 4, horizontal: AppSizes.sm),
          decoration: cardDecoration(),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _SummaryItem(value: aranan, label: 'Aranan ürün')),
                const _SummaryDivider(),
                Expanded(child: _SummaryItem(value: makale, label: 'Okunan makale')),
                const _SummaryDivider(),
                Expanded(
                    child: _SummaryItem(value: mekan, label: 'Keşfedilen mekan')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) => VerticalDivider(
        width: 1,
        thickness: 1,
        color: kOutlineVariant.withValues(alpha: 0.6),
      );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: GoogleFonts.manrope(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontXxl + 4,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
