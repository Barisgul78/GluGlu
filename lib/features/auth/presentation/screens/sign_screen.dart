import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bubble_background.dart';
import '../../../../../core/utils/snackbars.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/constants/app_sizes.dart';

class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> {
  bool _guestLoading = false;

  Future<void> _continueAsGuest() async {
    setState(() => _guestLoading = true);
    try {
      await AuthService.signInAnonymously();
      if (!mounted) return;
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      debugPrint('Misafir giriş hatası — kod: ${e.code}, mesaj: ${e.message}');
      if (!mounted) return;
      showErrorSnackBar(context, AuthService.errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _guestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          const BubbleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingHWide),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 52),

                  // ── Başlık ────────────────────────────────────────────
                  Text(
                    'GluGlu',
                    style: GoogleFonts.manrope(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.space10),

                  Text(
                    'Glutensiz yaşamın en kolay yolu.\nÜrünleri keşfedin, restoranları bulun ve\nkendi listenizi oluşturun.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      color: kOnSurfaceVariant,
                      fontSize: AppSizes.fontMd,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),

                  const SizedBox(height: AppSizes.space28),

                  // ── Görsel kart ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius20),
                    child: Image.asset(
                      'assets/images/sign.icon.jpg',
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 210,
                        color: kSurfaceContainerHigh,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grain,
                                size: 52,
                                color: kSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Glutensiz Ürünler',
                              style: GoogleFonts.manrope(
                                  color: kOnSurfaceVariant, fontSize: AppSizes.font13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Giriş Yap butonu ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => context.push('/sign/login'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Giriş Yap',
                            style: GoogleFonts.manrope(
                              fontSize: AppSizes.fontLg,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.space12),

                  // ── Kayıt Ol butonu ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => context.push('/sign/register'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius30),
                        ),
                      ),
                      child: Text(
                        'Kayıt Ol',
                        style: GoogleFonts.manrope(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.space28),

                  // ── Alt linkler ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _guestLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kPrimary),
                            )
                          : TextButton(
                              onPressed: _continueAsGuest,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Hesap oluşturmadan devam et',
                                style: GoogleFonts.manrope(
                                    color: kOnSurfaceVariant, fontSize: AppSizes.font13, fontWeight: FontWeight.w600),
                              ),
                            ),
                      Text(
                        '  |  ',
                        style: TextStyle(
                            color: kOutlineVariant.withValues(alpha: 0.7),
                            fontSize: AppSizes.font13),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Gizlilik politikası sayfası
                        },
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: AppSizes.xs),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Gizlilik',
                          style: GoogleFonts.manrope(
                              color: kOnSurfaceVariant, fontSize: AppSizes.font13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
