import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _shortDate = DateFormat('dd/MM/yyyy');
  static final _monthYear = DateFormat('MMM yyyy', 'id_ID');
  static final _apiFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return _dateFormat.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return _dateTimeFormat.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatShort(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return _shortDate.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  static String formatMonthYear(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return _monthYear.format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  static String toApiDate(DateTime date) => _apiFormat.format(date);

  static String timeAgo(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return formatDate(isoDate);
      if (diff.inDays > 0) return '${diff.inDays} hari lalu';
      if (diff.inHours > 0) return '${diff.inHours} jam lalu';
      if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
      return 'Baru saja';
    } catch (_) {
      return '-';
    }
  }

  static int ageInMonths(String? tanggalLahir) {
    if (tanggalLahir == null) return 0;
    try {
      final birth = DateTime.parse(tanggalLahir);
      final now = DateTime.now();
      return (now.year - birth.year) * 12 + (now.month - birth.month);
    } catch (_) {
      return 0;
    }
  }
}
