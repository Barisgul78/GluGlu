import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../../../core/utils/string_utils.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/services/profile_service.dart';
import '../widgets/health_journey_card.dart';
import '../widgets/profile_ui.dart';
import '../widgets/stats_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Statik placeholder — rozet veri modeli henüz yok (onaylı karar)
  static const _badges = [
    _Badge(
      icon: Icons.center_focus_strong_outlined,
      title: 'İlk Tarama',
      bgColor: kPastelGreen,
      unlocked: true,
    ),
    _Badge(
      icon: Icons.explore_outlined,
      title: 'Kaşif',
      bgColor: kPastelOrange,
      unlocked: true,
    ),
    _Badge(
      icon: Icons.lock_outline,
      title: 'Tarif Ustası',
      bgColor: kSurfaceContainerHigh,
      unlocked: false,
      hint: '5 tarif ekle',
    ),
  ];

  Future<void> _signOut(BuildContext context) async {
    await AuthService.signOut();
    if (!context.mounted) return;
    context.go('/sign');
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = AuthService.isAnonymous;
    final uid = AuthService.currentUserId;
    final fallbackName = AuthService.currentUser?.displayName ?? 'Kullanıcı';
    final email =
        isAnonymous ? 'Misafir hesabı' : (AuthService.currentUser?.email ?? '');

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (isAnonymous || uid == null) ...[
                _buildIdentity(context, 'Misafir', email),
                const SizedBox(height: AppSizes.lg),
                _buildHealthCardLink(context),
                const SizedBox(height: AppSizes.md),
                const HealthJourneyCard(),
              ] else
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ProfileService.userStream(uid),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final ad = data?['ad'] as String? ?? '';
                    final soyad = data?['soyad'] as String? ?? '';
                    final combined = '$ad $soyad'.trim();
                    final displayName =
                        combined.isNotEmpty ? combined : fallbackName;
                    final kullaniciAdi = data?['kullaniciAdi'] as String?;
                    final subtitle =
                        (kullaniciAdi != null && kullaniciAdi.isNotEmpty)
                            ? '@$kullaniciAdi'
                            : email;
                    final firstName = ad.isNotEmpty
                        ? ad
                        : displayName.split(' ').first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIdentity(context, displayName, subtitle),
                        const SizedBox(height: AppSizes.lg),
                        _buildHealthCardLink(context),
                        const SizedBox(height: AppSizes.md),
                        HealthJourneyCard(firstName: firstName),
                      ],
                    );
                  },
                ),
              const SizedBox(height: AppSizes.lg),
              _buildSectionHeader(
                'Rozetlerim',
                actionLabel: 'Tümünü gör',
                onAction: () => showInfoSnackBar(context, 'Yakında'),
              ),
              const SizedBox(height: AppSizes.sm + 4),
              _buildBadgesRow(),
              const SizedBox(height: AppSizes.sm + 4),
              const NextBadgeCard(),
              const SizedBox(height: AppSizes.lg),
              _buildSectionHeader('Keşif özetim'),
              const SizedBox(height: AppSizes.sm + 4),
              const DiscoverySummaryCard(),
              const SizedBox(height: AppSizes.md),
              _buildHelpCard(context),
              const SizedBox(height: AppSizes.md),
              _buildLogoutButton(context),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profil',
              style: GoogleFonts.plusJakartaSans(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontHeading,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kOnPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kOnSurface.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.settings_outlined,
                  color: kOnSurface, size: AppSizes.iconMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, String displayName, String sub) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials(displayName),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: AppSizes.fontHeading,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: kOnSurface,
                  fontSize: AppSizes.fontXxl,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sourceSans3(
                  color: kOnSurfaceVariant,
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/profile/edit'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profili düzenle',
                        style: GoogleFonts.plusJakartaSans(
                          color: kOnSurface,
                          fontSize: AppSizes.fontMd - 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm - 2),
                      const Icon(Icons.edit_outlined,
                          color: kOnSurface, size: AppSizes.iconSm),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCardLink(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Anonim hesap çıkışta kaybolur; kart kalıcı bir hesaba bağlanmalı.
        if (AuthService.isAnonymous) {
          showInfoSnackBar(
              context, 'Sağlık kartı için hesap oluşturman gerekiyor.');
          return;
        }
        context.push('/saglik-karti');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md + 4),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kOnPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.badge_outlined,
                  color: kOnPrimary, size: AppSizes.iconMd),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sağlık kartım',
                    style: GoogleFonts.plusJakartaSans(
                      color: kOnPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontXl,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Beslenme ihtiyaçlarını kolayca paylaş.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sourceSans3(
                      color: kOnPrimary.withValues(alpha: 0.85),
                      fontSize: AppSizes.fontMd - 1,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kOnPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: kOnSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.fontXxl - 4,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Text(
                actionLabel,
                style: GoogleFonts.sourceSans3(
                  color: kOnSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMd,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBadgesRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _badges.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.sm + 4),
            Expanded(child: _BadgeCard(badge: _badges[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return GestureDetector(
      onTap: () => showInfoSnackBar(context, 'Yakında'),
      child: Container(
        decoration: cardDecoration(),
        child: const IconRow(
          icon: Icons.help_outline,
          iconBgColor: kSurfaceContainerHigh,
          title: 'Yardım ve destek',
          subtitle: 'Soruların için buradayız',
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () => _signOut(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: kOnSurface,
          side: const BorderSide(color: kOutlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        icon: const Icon(Icons.logout, size: AppSizes.iconMd - 4),
        label: Text(
          'Çıkış yap',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontLg,
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md, horizontal: AppSizes.sm),
      decoration: unlocked
          ? cardDecoration()
          : BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                BoxDecoration(color: badge.bgColor, shape: BoxShape.circle),
            child: Icon(
              badge.icon,
              color: unlocked ? kPrimary : kOutline,
              size: AppSizes.iconMd - 2,
            ),
          ),
          const SizedBox(height: AppSizes.sm + 4),
          Text(
            badge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: unlocked ? kOnSurface : kOnSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontMd - 1,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            unlocked ? '✓ Kazanıldı' : 'Kilitli',
            style: GoogleFonts.sourceSans3(
              color: unlocked ? kPrimary : kOnSurfaceVariant,
              fontSize: AppSizes.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (badge.hint != null)
            Text(
              badge.hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sourceSans3(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.fontSm - 1,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge {
  final IconData icon;
  final String title;
  final Color bgColor;
  final bool unlocked;
  final String? hint;

  const _Badge({
    required this.icon,
    required this.title,
    required this.bgColor,
    required this.unlocked,
    this.hint,
  });
}
