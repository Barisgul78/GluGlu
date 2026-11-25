import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../constants/app_sizes.dart';

// Primary dolu buton — loading ve disabled durumları destekler
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.width = double.infinity,
    this.height = AppSizes.buttonHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = AppSizes.radiusFull,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? kPrimary;
    final fg = foregroundColor ?? Colors.white;

    return SizedBox(
      width: width,
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: fg,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: AppSizes.iconMd - 4),
                    const SizedBox(width: AppSizes.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: AppSizes.fontLg,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Outlined (kenarlıklı) buton varyantı
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = AppSizes.buttonHeight,
    this.borderColor,
    this.textColor,
    this.borderRadius = AppSizes.radiusFull,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color? borderColor;
  final Color? textColor;
  final double borderRadius;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final baseColor = borderColor ?? kPrimary;
    final baseFg = textColor ?? kPrimary;
    final color = enabled ? baseColor : baseColor.withValues(alpha: 0.5);
    final fgColor = enabled ? baseFg : baseFg.withValues(alpha: 0.5);

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: fgColor,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
      ),
    );
  }
}
