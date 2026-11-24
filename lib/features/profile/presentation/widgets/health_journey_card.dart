import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../../core/utils/snackbars.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/profile_service.dart';
import 'diagnosis_date_picker.dart';

const _milestones = [
  100,
  500,
  1000,
  1500,
  2000,
  2500,
  3000,
  4000,
  5000,
  7500,
  10000
];

// Tanı yılına göre gün sayacı, yıl ilerlemesi ve milestone hesaplaması
class _HealthJourneyStats {
  final int totalDays;
  final int completedYears;
  final int nextYearNumber;
  final int daysToNextYear;
  final int totalDaysAtNextYear;
  final double yearProgress;
  final int? lastMilestone;

  const _HealthJourneyStats({
    required this.totalDays,
    required this.completedYears,
    required this.nextYearNumber,
    required this.daysToNextYear,
    required this.totalDaysAtNextYear,
    required this.yearProgress,
    required this.lastMilestone,
  });

  factory _HealthJourneyStats.calculate(DateTime diagnosisDate) {
    final start = diagnosisDate;
    final now = DateTime.now();
    final totalDays = now.difference(start).inDays;

    var completed = 0;
    while (!DateTime(start.year + completed + 1, start.month, 1).isAfter(now)) {
      completed++;
    }
    final yearStart = DateTime(start.year + completed, start.month, 1);
    final yearEnd = DateTime(start.year + completed + 1, start.month, 1);
    final daysInYear = yearEnd.difference(yearStart).inDays;
    final daysIntoYear = now.difference(yearStart).inDays;

    int? lastMilestone;
    for (final m in _milestones) {
      if (totalDays >= m) lastMilestone = m;
    }

    return _HealthJourneyStats(
      totalDays: totalDays,
      completedYears: completed,
      nextYearNumber: completed + 1,
      daysToNextYear: yearEnd.difference(now).inDays,
      totalDaysAtNextYear: yearEnd.difference(start).inDays,
      yearProgress: daysInYear == 0 ? 0 : daysIntoYear / daysInYear,
      lastMilestone: lastMilestone,
    );
  }
}

// Sağlık Profilim kartı: tanı yılı girilmemişse boş durum, girilmişse gün sayacı gösterir
class HealthJourneyCard extends StatelessWidget {
  const HealthJourneyCard({super.key, this.firstName = ''});

  final String firstName;

  BoxDecoration get _decoration => BoxDecoration(
        color: kOnPrimary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: kOnSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // current doluysa düzenleme: seçici kayıtlı tarihle açılır.
  Future<void> _openPicker(BuildContext context, {DateTime? current}) async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      showInfoSnackBar(
          context, 'Tanı yılını eklemek için giriş yapmanız gerekiyor.');
      return;
    }
    final date = await showDiagnosisDatePicker(context, initialDate: current);
    if (date == null) return;
    if (current != null &&
        current.year == date.year &&
        current.month == date.month) {
      return;
    }
    try {
      await ProfileService.setDiagnosisDate(userId, date);
    } catch (e) {
      debugPrint('Tanı tarihi kaydedilemedi: $e');
      if (context.mounted) {
        showErrorSnackBar(
            context, 'Tanı tarihi kaydedilemedi. Lütfen tekrar deneyin.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return _EmptyState(
          decoration: _decoration, onAddPressed: () => _openPicker(context));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ProfileService.userStream(userId),
      builder: (context, snapshot) {
        final timestamp = snapshot.data?.data()?['tani_tarihi'] as Timestamp?;

        if (timestamp == null) {
          return _EmptyState(
              decoration: _decoration,
              onAddPressed: () => _openPicker(context));
        }

        final diagnosisDate = timestamp.toDate();
        final stats = _HealthJourneyStats.calculate(diagnosisDate);
        return _FilledState(
          firstName: firstName,
          diagnosisDate: diagnosisDate,
          stats: stats,
          onEditPressed: () => _openPicker(context, current: diagnosisDate),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.decoration, required this.onAddPressed});

  final BoxDecoration decoration;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: decoration.copyWith(
        border: Border.all(color: kOutlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: kPastelGreen, shape: BoxShape.circle),
            child: const Icon(Icons.eco_outlined, color: kPrimary, size: 28),
          ),
          const SizedBox(height: AppSizes.space14),
          Text(
            'Çölyak Yolculuğun',
            style: GoogleFonts.manrope(
              color: kOnSurface,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontLg,
            ),
          ),
          const SizedBox(height: AppSizes.space6),
          Text(
            'Tanı yılını ekle, glutensiz yolculuğunun kaç gündür sürdüğünü birlikte görelim!',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.font13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddPressed,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: kOnPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius30)),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH, vertical: AppSizes.space12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Tanı Yılımı Ekle',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledState extends StatelessWidget {
  const _FilledState({
    required this.firstName,
    required this.diagnosisDate,
    required this.stats,
    required this.onEditPressed,
  });

  final String firstName;
  final DateTime diagnosisDate;
  final _HealthJourneyStats stats;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final target = stats.totalDaysAtNextYear;
    final progress = target == 0 ? 0.0 : stats.totalDays / target;
    final title = firstName.isNotEmpty
        ? 'Her adımın değerli, $firstName!'
        : 'Her adımın değerli!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md + AppSizes.xs),
      decoration: BoxDecoration(
        color: kPrimaryFixed.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: kOutlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GLUTENSİZ YAŞAM YOLCULUĞUM',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontXs + 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSizes.sm + 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: kOnSurface,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontXl + 2,
            ),
          ),
          const SizedBox(height: AppSizes.sm + 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${stats.totalDays}',
                style: GoogleFonts.manrope(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: AppSizes.sm + 4),
              Text(
                'gün\nglutensiz',
                style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Sıradaki dönüm noktası: $target gün',
            style: GoogleFonts.manrope(
              color: kOnSurface,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontMd - 1,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: progress.clamp(0.0, 1.0),
            backgroundColor: kOnPrimary,
            progressColor: kPrimary,
            barRadius: const Radius.circular(AppSizes.radiusFull),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSizes.sm - 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.totalDays} / $target gün',
                style: GoogleFonts.manrope(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${stats.daysToNextYear} gün kaldı',
                style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Küçük adımlar, büyük bir yolculuk.',
            style: GoogleFonts.manrope(
              color: kOnSurfaceVariant,
              fontSize: AppSizes.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.sm + 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Başlangıç: ${du.formatMonthYear(diagnosisDate)}',
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEditPressed,
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSm),
                label: Text(
                  'Düzenle',
                  style: GoogleFonts.manrope(
                    fontSize: AppSizes.fontSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
