import 'package:flutter/material.dart';

/// Display + spoken (TTS) formatting helpers. Spoken versions are written for
/// the Hindi TTS voice so numbers sound natural ("16 hazaar 800 rupaye").
class Fmt {
  Fmt._();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _days = ['Somvar', 'Mangalvar', 'Budhvar', 'Guruvar', 'Shukravar', 'Shanivar', 'Ravivar'];

  /// ₹16,800 (Indian grouping).
  static String rupees(num amount) {
    final n = amount.round();
    final neg = n < 0;
    var s = n.abs().toString();
    if (s.length > 3) {
      final last3 = s.substring(s.length - 3);
      var rest = s.substring(0, s.length - 3);
      final parts = <String>[];
      while (rest.length > 2) {
        parts.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) parts.insert(0, rest);
      s = '${parts.join(',')},$last3';
    }
    return '${neg ? '-' : ''}₹$s';
  }

  /// "16 hazaar 800 rupaye"
  static String rupeesSpoken(num amount) {
    final n = amount.round();
    if (n == 0) return 'shunya rupaye';
    final lakh = n ~/ 100000;
    final thousand = (n % 100000) ~/ 1000;
    final rest = n % 1000;
    final parts = <String>[];
    if (lakh > 0) parts.add('$lakh lakh');
    if (thousand > 0) parts.add('$thousand hazaar');
    if (rest > 0) parts.add('$rest');
    return '${parts.join(' ')} rupaye';
  }

  /// 8:00 AM
  static String time(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  /// "subah 8 baje", "dopahar 1:30 baje", "shaam 5 baje"
  static String timeSpoken(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final part = switch (t.hour) {
      < 4 => 'raat',
      < 12 => 'subah',
      < 16 => 'dopahar',
      < 19 => 'shaam',
      _ => 'raat',
    };
    final clock = switch (t.minute) {
      0 => '$h baje',
      30 => 'saadhe $h baje',
      15 => 'sava $h baje',
      _ => '$h baj kar ${t.minute} minute',
    };
    return '$part $clock';
  }

  /// 10 October
  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// Mangalvar, 10 October
  static String dateWithDay(DateTime d) => '${_days[d.weekday - 1]}, ${date(d)}';

  static String weekday(DateTime d) => _days[d.weekday - 1];

  /// "aaj", "kal", "10 October"
  static String relativeDay(DateTime d, DateTime now) {
    final diff = dayOnly(d).difference(dayOnly(now)).inDays;
    if (diff == 0) return 'Aaj';
    if (diff == 1) return 'Kal';
    if (diff == -1) return 'Kal (beeta hua)';
    return date(d);
  }

  static String durationMinutes(int minutes) {
    if (minutes < 60) return '$minutes minute';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hs = h == 1 ? '1 ghanta' : '$h ghante';
    return m == 0 ? hs : '$hs $m minute';
  }

  static String ago(DateTime t, DateTime now) {
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'Abhi';
    if (d.inMinutes < 60) return '${d.inMinutes} min pehle';
    if (d.inHours < 24) return '${d.inHours} ghante pehle';
    if (d.inDays == 1) return 'Kal';
    return date(t);
  }

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  static String days(int n) => n == 1 ? '1 din' : '$n din';
}
