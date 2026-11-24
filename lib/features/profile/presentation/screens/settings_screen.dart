import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../auth/data/services/auth_service.dart';
import '../widgets/profile_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeleting = false;

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        title: Text(
          'Hesabı silmek istediğine emin misin?',
          style: GoogleFonts.manrope(
            color: kOnSurface,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.font17,
          ),
        ),
        content: Text(
          'Bu işlem geri alınamaz. Tüm ürün/mekan/makale favorilerin ve profil bilgilerin kalıcı olarak silinir.',
          style: GoogleFonts.manrope(
            color: kOnSurfaceVariant,
            fontSize: AppSizes.fontMd,
            fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Vazgeç',
                style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Sil',
                style: GoogleFonts.manrope(
                    color: kError, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _isDeleting = true);
    try {
      await AuthService.deleteAccount();
      if (!context.mounted) return;
      context.go('/sign');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      showErrorSnackBar(context, AuthService.errorMessage(e.code));
    } catch (_) {
      if (!context.mounted) return;
      showErrorSnackBar(context, 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _soon() => showInfoSnackBar(context, 'Yakında');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileHeader(title: 'Ayarlar'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH,
                  vertical: AppSizes.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionHeading('Tercihler'),
                    _buildPreferencesGroup(),
                    const SizedBox(height: AppSizes.lg),
                    sectionHeading('Hakkında ve yasal'),
                    _buildAboutSection(),
                    const SizedBox(height: AppSizes.lg),
                    sectionHeading('Bağlantıda kal'),
                    _buildSocialRow(),
                    const SizedBox(height: AppSizes.lg),
                    sectionHeading('Hesap yönetimi'),
                    _buildAccountSection(),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tercihler (gerçek tema/dil geçişi bağlı değil — dokunuş "Yakında" der) ──
  Widget _buildPreferencesGroup() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.dark_mode_outlined,
            title: 'Karanlık mod',
            subtitle: 'Koyu tema kullan',
            trailing: Switch(value: false, onChanged: (_) => _soon()),
          ),
          sectionDivider(),
          const _SettingsRow(
            icon: Icons.language_outlined,
            title: 'Dil seçimi',
            subtitle: 'Uygulama dili',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, 0, AppSizes.md, AppSizes.md),
            child: _LanguageSegments(onTap: _soon),
          ),
        ],
      ),
    );
  }

  // ── Hakkında ve yasal (hardcoded) ─────────────────────────────────────────
  Widget _buildAboutSection() {
    return Column(
      children: [
        Container(
          decoration: _cardDecoration(
            color: kPrimaryFixed.withValues(alpha: 0.45),
          ),
          child: _SettingsRow(
            icon: Icons.eco_outlined,
            iconBg: kPrimaryFixed.withValues(alpha: 0.7),
            title: 'GluGlu',
            subtitle: 'Çölyak yaşam rehberi',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space10, vertical: AppSizes.xs),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontSize: AppSizes.fontSm - 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm + 4),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.lock_outline,
                title: 'Gizlilik Politikası',
                onTap: _soon,
                trailing: const _Chevron(),
              ),
              sectionDivider(),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                onTap: _soon,
                trailing: const _Chevron(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bağlantıda kal (hardcoded) ────────────────────────────────────────────
  Widget _buildSocialRow() {
    const gap = SizedBox(width: AppSizes.sm + 4);
    return Row(
      children: [
        Expanded(child: _SocialTile(
            icon: Icons.camera_alt_outlined, label: 'Instagram', onTap: _soon)),
        gap,
        Expanded(child: _SocialTile(
            icon: Icons.close_rounded, label: 'X', onTap: _soon)),
        gap,
        Expanded(child: _SocialTile(
            icon: Icons.smart_display_outlined, label: 'YouTube', onTap: _soon)),
        gap,
        Expanded(child: _SocialTile(
            icon: Icons.mail_outline, label: 'E-posta', onTap: _soon)),
      ],
    );
  }

  // ── Hesap yönetimi (veri indirme "Yakında"; hesap silme gerçek) ───────────
  Widget _buildAccountSection() {
    return Column(
      children: [
        Container(
          decoration: _cardDecoration(),
          child: _SettingsRow(
            icon: Icons.download_outlined,
            title: 'Verilerimi indir',
            subtitle: 'GDPR kapsamında tüm verilerini al',
            onTap: _soon,
            trailing: const _Chevron(),
          ),
        ),
        const SizedBox(height: AppSizes.sm + 4),
        Container(
          decoration: cardDecoration(
            color: kErrorContainer.withValues(alpha: 0.6),
            borderColor: kError.withValues(alpha: 0.3),
            radius: AppSizes.radiusXl - 4,
          ),
          child: _SettingsRow(
            icon: Icons.delete_outline,
            iconBg: kError.withValues(alpha: 0.12),
            iconColor: kError,
            title: 'Hesabı sil',
            subtitle: 'Tüm verilerin kalıcı olarak silinir',
            titleColor: kOnErrorContainer,
            subtitleColor: kError,
            onTap: _isDeleting ? null : () => _confirmAndDeleteAccount(context),
            trailing: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kError),
                  )
                : const _Chevron(color: kError),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({Color color = kOnPrimary}) =>
      cardDecoration(color: color, radius: AppSizes.radiusXl - 4);
}

// Kart içi satır: yuvarlak-kare pastel ikon kutusu + başlık/alt yazı + sağ eleman.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBg = kPastelGreen,
    this.iconColor = kPrimary,
    this.titleColor = kOnSurface,
    this.subtitleColor = kOnSurfaceVariant,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: AppSizes.icon22),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSizes.space2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: subtitleColor,
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSizes.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({this.color = kOnSurfaceVariant});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, color: color, size: AppSizes.icon22);
}

// Türkçe / English seçici — dil geçişi henüz bağlı değil, Türkçe seçili sabit.
class _LanguageSegments extends StatelessWidget {
  const _LanguageSegments({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xs),
        decoration: BoxDecoration(
          color: kPastelGray,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm + 4),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd - 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, color: Colors.white, size: AppSizes.iconSm),
                    const SizedBox(width: AppSizes.sm - 2),
                    Text(
                      'Türkçe',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.fontMd,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'English',
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: AppSizes.fontMd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// "Bağlantıda kal" karosu: üstte ikon, altında etiket.
class _SocialTile extends StatelessWidget {
  const _SocialTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md,
          horizontal: AppSizes.xs,
        ),
        decoration: cardDecoration(radius: AppSizes.radiusLg),
        child: Column(
          children: [
            Icon(icon, color: kOnSurfaceVariant, size: AppSizes.icon22),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontSize: AppSizes.fontSm - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
