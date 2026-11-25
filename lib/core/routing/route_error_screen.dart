import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_sizes.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';

// Eşleşmeyen yol veya eksik/bozuk extra ile açılan rotalar için ortak ekran.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPaddingH,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_off_outlined,
                  size: 52,
                  color: kOutlineVariant,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Sayfa bulunamadı',
                  style: GoogleFonts.manrope(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Aradığın sayfa açılamadı. Ana sayfaya dönebilirsin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: AppSizes.font13,
                    fontWeight: FontWeight.w500,
                    color: kOnSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                AppButton(
                  label: 'Ana sayfaya dön',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
