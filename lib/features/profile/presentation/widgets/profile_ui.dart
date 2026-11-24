import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';

// Profil ve Ayarlar ekranları arasında paylaşılan kart/satır stilleri.
// (Bu iki ekran aynı dosyanın bölünmesiyle oluştu, ortak görsel dil taşıyorlar.)

BoxDecoration cardDecoration({
  Color color = kOnPrimary,
  Color? borderColor,
  double radius = 16,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: borderColor != null ? Border.all(color: borderColor) : null,
    boxShadow: borderColor == null
        ? [
            BoxShadow(
              color: kOnSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : null,
  );
}

Widget sectionDivider() => Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: kOutlineVariant.withValues(alpha: 0.6),
    );

// Tam ekran alt sayfaların üst çubuğu: yuvarlak beyaz geri butonu + büyük başlık.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.sm + AppSizes.xs,
        AppSizes.screenPaddingH,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: kOnSurface, size: AppSizes.icon22),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontXxl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kartın dışında, üstünde duran sentence-case bölüm başlığı.
Widget sectionHeading(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm + 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.manrope(
          color: kOnSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ),
  );
}

// Ortak ikon+başlık+alt yazı düzeni (Profil'deki sağlık/ayarlar satırları, Ayarlar'daki tüm satırlar)
class IconRow extends StatelessWidget {
  const IconRow({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.titleColor = kOnSurface,
    this.subtitleColor = kOnSurfaceVariant,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.space14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: kPrimary, size: AppSizes.icon20),
          ),
          const SizedBox(width: AppSizes.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                    style: GoogleFonts.manrope(
                        color: subtitleColor, fontSize: AppSizes.fontSm, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (trailing != null) trailing!,
              ],
            ),
          ),
          if (showChevron)
            const Icon(Icons.chevron_right, color: kOutlineVariant, size: AppSizes.icon20),
        ],
      ),
    );
  }
}
