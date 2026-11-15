import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/health_card.dart';

// Sağlık kartı ekranlarının üst çubuğu: ← + başlık + opsiyonel sağ eleman.
class HealthCardAppBar extends StatelessWidget {
  const HealthCardAppBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.sm,
        AppSizes.screenPaddingH,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.fontXl,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// Mekânda gösterilen/paylaşılan kartın kendisi. scale: tam ekranda yazıları büyütür.
class HealthCardView extends StatelessWidget {
  const HealthCardView({super.key, required this.card, this.scale = 1});

  final HealthCard card;
  final double scale;

  double _s(double v) => v * scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: kOutlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: kOnSurface.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildHeader(), _buildBody()],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: kPrimary,
      padding: EdgeInsets.all(_s(AppSizes.md + 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'gluglu',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: _s(AppSizes.fontLg),
                ),
              ),
              const Spacer(),
              Text(
                'BESLENME KARTI',
                style: GoogleFonts.manrope(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: _s(AppSizes.fontXs + 1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: _s(AppSizes.sm + 4)),
          Text(
            card.adSoyad,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: _s(AppSizes.fontHeading),
              height: 1.15,
            ),
          ),
          SizedBox(height: _s(AppSizes.xs + 2)),
          Text(
            card.needsLine,
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: _s(AppSizes.fontMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.all(_s(AppSizes.md + 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gluten tüketemiyorum.',
            style: GoogleFonts.manrope(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: _s(AppSizes.fontXxl),
            ),
          ),
          SizedBox(height: _s(AppSizes.sm + 4)),
          Text(
            card.avoidSentence,
            style: GoogleFonts.manrope(
              color: kOnSurface,
              fontWeight: FontWeight.w600,
              fontSize: _s(AppSizes.fontLg + 1),
              height: 1.4,
            ),
          ),
          if (card.crossContact) ...[
            SizedBox(height: _s(AppSizes.md)),
            _buildCrossContactBox(),
          ],
          if (card.note.trim().isNotEmpty) ...[
            SizedBox(height: _s(AppSizes.md)),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Not: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: card.note.trim()),
                ],
              ),
              style: GoogleFonts.manrope(
                color: kOnSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: _s(AppSizes.fontMd),
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: _s(AppSizes.md + 4)),
          Text(
            'Desteğiniz için teşekkür ederim.',
            style: GoogleFonts.manrope(
              color: kPrimary,
              fontWeight: FontWeight.w600,
              fontSize: _s(AppSizes.fontMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossContactBox() {
    return Container(
      padding: EdgeInsets.all(_s(AppSizes.md)),
      decoration: BoxDecoration(
        color: kPastelOrange,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: kSecondary, size: _s(AppSizes.iconMd - 2)),
          SizedBox(width: _s(AppSizes.sm + 4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çapraz temasa dikkat',
                  style: GoogleFonts.manrope(
                    color: kSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: _s(AppSizes.fontMd + 1),
                  ),
                ),
                SizedBox(height: _s(AppSizes.xs)),
                Text(
                  'Ayrı ve temiz ekipman kullanılması, ortak yağ ve yüzeylerden kaçınılması önemlidir.',
                  style: GoogleFonts.manrope(
                    color: kOnSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: _s(AppSizes.fontSm + 1),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
