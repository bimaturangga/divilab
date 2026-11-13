/// Format tanggal Bahasa Indonesia tanpa dependensi tambahan.
class DateFmt {
  DateFmt._();

  static const months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const dayInitials = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  static String _2(int v) => v.toString().padLeft(2, '0');

  /// 14:05
  static String time(DateTime d) => '${_2(d.hour)}:${_2(d.minute)}';

  /// 14 Sep 2026
  static String dateShort(DateTime d) => '${d.day} ${monthsShort[d.month - 1]} ${d.year}';

  /// 14 September 2026
  static String dateLong(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

  /// 14 Sep 2026, 15:46
  static String dateTime(DateTime d) => '${dateShort(d)}, ${time(d)}';

  /// Senin, 14 Sep 2026 / "Hari ini" / "Kemarin"
  static String dayHeader(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '${days[d.weekday - 1]}, ${dateShort(d)}';
  }

  /// 8 – 14 Sep 2026
  static String range(DateTime a, DateTime b) {
    if (a.year == b.year && a.month == b.month) {
      return '${a.day} – ${b.day} ${monthsShort[b.month - 1]} ${b.year}';
    }
    return '${dateShort(a)} – ${dateShort(b)}';
  }

  static String monthYear(DateTime d) => '${months[d.month - 1]} ${d.year}';

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  static int ageFrom(DateTime birth, {DateTime? now}) {
    final n = now ?? DateTime.now();
    var age = n.year - birth.year;
    if (n.month < birth.month || (n.month == birth.month && n.day < birth.day)) age--;
    return age;
  }
}
