/// Thai (Buddhist Era, พ.ศ.) date helpers.
///
/// The API / database always use Gregorian years (e.g. a CHECK of 2000..2100 on
/// `year` columns). The UI shows and asks for พ.ศ. everywhere, so every screen
/// converts through these helpers instead of adding/subtracting 543 by hand.
class ThaiDate {
  static const int beOffset = 543;

  static const List<String> monthShort = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// Gregorian year -> พ.ศ.
  static int toBe(int adYear) => adYear + beOffset;

  /// พ.ศ. -> Gregorian. Values that already look Gregorian (< 2400) are kept,
  /// so someone typing "2026" instead of "2569" still saves a valid year.
  static int toAd(int year) => year >= 2400 ? year - beOffset : year;

  /// Text for a year input field / label (Gregorian value in, พ.ศ. text out).
  /// Returns '' for null / unparsable values.
  static String yearText(dynamic adYear) {
    final y = adYear is num ? adYear.toInt() : int.tryParse(adYear?.toString() ?? '');
    return y == null ? '' : toBe(y).toString();
  }

  /// Parses what the user typed in a year field to the Gregorian year to send to the API.
  static int? yearFromInput(String text) {
    final y = int.tryParse(text.trim());
    return y == null ? null : toAd(y);
  }

  /// "พ.ย. 2569"
  static String monthYear(int month, int adYear) {
    if (month < 1 || month > 12) return toBe(adYear).toString();
    return '${monthShort[month]} ${toBe(adYear)}';
  }

  /// "3/11/2569"
  static String date(DateTime d) => '${d.day}/${d.month}/${toBe(d.year)}';

  /// "03/11/2569 19:31"
  static String dateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${toBe(d.year)} ${two(d.hour)}:${two(d.minute)}';
  }
}
