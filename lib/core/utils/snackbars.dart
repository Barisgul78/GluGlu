import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../constants/app_sizes.dart';

// Hata mesajı için standart snackbar
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
      backgroundColor: kError,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      margin: const EdgeInsets.all(AppSizes.md),
    ),
  );
}

// Bilgilendirme mesajı için standart snackbar (örn. henüz yapılmamış özellik)
void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message,
          style: GoogleFonts.manrope(
              color: kOnSurface, fontWeight: FontWeight.w600)),
      backgroundColor: kSurfaceContainerHigh,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      margin: const EdgeInsets.all(AppSizes.md),
    ),
  );
}
