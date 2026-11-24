import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_sizes.dart';

// Tanı ayı+yılı seçimi için alttan açılan iki tekerlekli seçici (3. parti paket yok).
// initialDate verilirse seçici o ay/yılla açılır (düzenleme); yoksa bugünle açılır.
Future<DateTime?> showDiagnosisDatePicker(BuildContext context, {DateTime? initialDate}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: kOnPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radius20)),
    ),
    builder: (sheetContext) => _DiagnosisDatePickerSheet(initialDate: initialDate),
  );
}

class _DiagnosisDatePickerSheet extends StatefulWidget {
  const _DiagnosisDatePickerSheet({this.initialDate});

  final DateTime? initialDate;

  @override
  State<_DiagnosisDatePickerSheet> createState() => _DiagnosisDatePickerSheetState();
}

class _DiagnosisDatePickerSheetState extends State<_DiagnosisDatePickerSheet> {
  static final _now = DateTime.now();
  static final _years = List<int>.generate(80, (i) => _now.year - i); // azalan, gelecek yıl yok

  late int _selectedYear;
  late int _selectedMonth;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    if (initial != null && _years.contains(initial.year)) {
      _selectedYear = initial.year;
      final maxMonth = _selectedYear == _now.year ? _now.month : 12;
      _selectedMonth = math.min(initial.month, maxMonth);
    } else {
      _selectedYear = _years.first;
      _selectedMonth = _now.month;
    }
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_selectedYear));
  }

  List<int> get _availableMonths {
    final maxMonth = _selectedYear == _now.year ? _now.month : 12;
    return List<int>.generate(maxMonth, (i) => i + 1);
  }

  void _onYearChanged(int index) {
    final newYear = _years[index];
    final months = _selectedYear == newYear
        ? _availableMonths
        : List<int>.generate(newYear == _now.year ? _now.month : 12, (i) => i + 1);
    setState(() {
      _selectedYear = newYear;
      if (_selectedMonth > months.length) {
        _selectedMonth = months.length;
        _monthController.jumpToItem(_selectedMonth - 1);
      }
    });
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _availableMonths;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.space12, bottom: AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              'Tanı Tarihini Seç',
              style: GoogleFonts.manrope(
                color: kOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.font17,
              ),
            ),
            SizedBox(
              height: 216,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: _monthController,
                      onSelectedItemChanged: (index) =>
                          setState(() => _selectedMonth = months[index]),
                      children: months
                          .map((m) => Center(
                                child: Text(
                                  du.monthName(m),
                                  style: GoogleFonts.manrope(
                                    color: kOnSurface,
                                    fontSize: AppSizes.font17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: _yearController,
                      onSelectedItemChanged: _onYearChanged,
                      children: _years
                          .map((y) => Center(
                                child: Text(
                                  '$y',
                                  style: GoogleFonts.manrope(
                                    color: kOnSurface,
                                    fontSize: AppSizes.font17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
              child: AppButton(
                label: 'Kaydet',
                onPressed: () => Navigator.of(context)
                    .pop(DateTime(_selectedYear, _selectedMonth, 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
