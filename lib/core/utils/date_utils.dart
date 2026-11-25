const _months = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month]} ${date.year}';

String formatMonthYear(DateTime date) => '${_months[date.month]} ${date.year}';

String monthName(int month) =>
    (month < 1 || month > 12) ? '' : _months[month];
