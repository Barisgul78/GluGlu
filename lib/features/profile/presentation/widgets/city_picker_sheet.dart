import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/turkish_cities.dart';

// Şehir seçimi için alttan açılan, kaydırılabilir il listesi.
Future<String?> showCityPickerSheet(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kOnPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSizes.sm + 4),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Şehir seç',
                style: GoogleFonts.manrope(
                  color: kOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: AppSizes.fontXl,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPaddingH,
                  ),
                  itemCount: kTurkishCities.length,
                  itemBuilder: (_, i) {
                    final city = kTurkishCities[i];
                    final isSelected = city == selected;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        city,
                        style: GoogleFonts.manrope(
                          color: isSelected ? kPrimary : kOnSurface,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: AppSizes.font15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: kPrimary, size: AppSizes.icon20)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(city),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      );
    },
  );
}
