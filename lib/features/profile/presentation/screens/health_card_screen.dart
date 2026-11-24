import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/models/health_card.dart';
import '../../data/services/profile_service.dart';
import '../widgets/health_card_widgets.dart';
import 'health_card_form_screen.dart';

// /saglik-karti: kart yoksa oluşturma formu, varsa "Sağlık kartım" görünümü.
class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  // Paylaşılacak PNG'nin kaynağı: kartı saran RepaintBoundary
  final _cardKey = GlobalKey();
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _stream = _openStream();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _openStream() {
    final uid = AuthService.currentUserId;
    return uid == null ? null : ProfileService.userStream(uid);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Kart çizimi bulunamadı');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG üretilemedi');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'saglik_karti.png',
            ),
          ],
          fileNameOverrides: const ['saglik_karti.png'],
        ),
      );
    } catch (e) {
      debugPrint('Sağlık kartı paylaşılamadı: $e');
      if (mounted) {
        showErrorSnackBar(context, 'Paylaşım açılamadı. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) {
      return _message(
        'Sağlık kartını görmek için\ngiriş yapman gerekiyor.',
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Sağlık kartı okunamadı: ${snapshot.error}');
          return _message(
            'Sağlık kartın yüklenemedi.\nLütfen tekrar dene.',
            onRetry: () => setState(() => _stream = _openStream()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: kBackground,
            body: Center(child: CircularProgressIndicator(color: kPrimary)),
          );
        }
        final card = HealthCard.fromMap(
          snapshot.data!.data()?['saglik_karti'] as Map<String, dynamic>?,
        );
        if (card == null) return const HealthCardFormScreen();
        return _buildCard(card);
      },
    );
  }

  Widget _message(String text, {VoidCallback? onRetry}) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            const HealthCardAppBar(title: 'Sağlık kartım'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPaddingHWide),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          color: kOnSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontMd,
                          height: 1.5,
                        ),
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: AppSizes.md),
                        TextButton(
                          onPressed: onRetry,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(HealthCard card) {
    // Kartın etrafındaki sm boşluk PNG'de gölgenin kırpılmaması içindir;
    // diğer öğeler aynı sm kadar içeri alınarak hizalı kalır.
    const inset = EdgeInsets.symmetric(horizontal: AppSizes.sm);
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            HealthCardAppBar(
              title: 'Sağlık kartım',
              trailing: GestureDetector(
                onTap: () => context.push('/saglik-karti/duzenle', extra: card),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: kPrimary, size: AppSizes.icon20),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH - AppSizes.sm,
                  vertical: AppSizes.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: inset,
                      child: Text(
                        'İhtiyaçların, tek kartta.',
                        style: GoogleFonts.manrope(
                          color: kOnSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.fontXxl,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs + 2),
                    Padding(
                      padding: inset,
                      child: Text(
                        'Mekânda göster, beslenme ihtiyaçlarını anlat.',
                        style: GoogleFonts.manrope(
                          color: kOnSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: AppSizes.fontMd,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    RepaintBoundary(
                      key: _cardKey,
                      child: Container(
                        color: kBackground,
                        padding: const EdgeInsets.all(AppSizes.sm),
                        child: HealthCardView(card: card),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm + 4),
                    Padding(
                      padding: inset,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: kOnSurfaceVariant, size: AppSizes.icon20),
                          const SizedBox(width: AppSizes.sm + 4),
                          Expanded(
                            child: Text(
                              'Bu kart kullanıcı beyanına dayanır; tıbbi belge değildir. Paylaşmadan önce bilgilerini kontrol et.',
                              style: GoogleFonts.manrope(
                                color: kOnSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: AppSizes.fontSm + 1,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Padding(
                      padding: inset,
                      child: Column(
                        children: [
                          _primaryButton(
                            label: 'Kartı tam ekran göster',
                            icon: Icons.fullscreen,
                            onPressed: () => context.push(
                              '/saglik-karti/tam-ekran',
                              extra: card,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm + 4),
                          _secondaryButton(
                            label: 'Kartı paylaş',
                            icon: Icons.ios_share,
                            loading: _sharing,
                            onPressed: _share,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSizes.iconMd - 2),
        label: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: AppSizes.fontLg,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
              )
            : Icon(icon, size: AppSizes.iconMd - 4),
        label: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: AppSizes.fontLg,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: kPrimary,
          side: BorderSide(color: kOutlineVariant.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
        ),
      ),
    );
  }
}
