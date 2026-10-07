import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings.dart';
import 'l10n.dart';

/// Money, number and date formatting that follows Bangladeshi conventions:
/// lakh/crore grouping (1,25,000), the ৳ sign and optional Bangla numerals.
class Fmt {
  const Fmt({required this.bn, required this.bnNum});
  final bool bn;
  final bool bnNum;

  static Fmt of(BuildContext context) {
    final s = context.watch<Settings>();
    return Fmt(bn: s.isBangla, bnNum: s.useBanglaDigits);
  }

  static Fmt read(BuildContext context) {
    final s = context.read<Settings>();
    return Fmt(bn: s.isBangla, bnNum: s.useBanglaDigits);
  }

  String _d(String s) => bnNum ? toBnDigits(s) : s;

  /// 125000 → "1,25,000"
  String number(num value, {int decimals = 0}) {
    final neg = value < 0;
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final digits = parts[0];
    String grouped;
    if (digits.length <= 3) {
      grouped = digits;
    } else {
      final last3 = digits.substring(digits.length - 3);
      var rest = digits.substring(0, digits.length - 3);
      final chunks = <String>[];
      while (rest.length > 2) {
        chunks.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) chunks.insert(0, rest);
      grouped = '${chunks.join(',')},$last3';
    }
    final out = parts.length > 1 && int.parse(parts[1]) != 0 ? '$grouped.${parts[1]}' : grouped;
    return _d(neg ? '-$out' : out);
  }

  /// "৳ 1,25,000"
  String money(num value, {bool sign = false}) {
    final s = number(value.abs());
    final prefix = value < 0 ? '−' : (sign && value > 0 ? '+' : '');
    return '$prefix৳$s';
  }

  /// Compact: 1.2L / ১.২ লাখ, 3.4Cr, 12.5K
  String compact(num value) {
    final v = value.abs();
    final neg = value < 0 ? '−' : '';
    String trim(double x) {
      final s = x.toStringAsFixed(x >= 100 ? 0 : 1);
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    if (v >= 10000000) return '$neg৳${_d(trim(v / 10000000))}${bn ? ' কোটি' : 'Cr'}';
    if (v >= 100000) return '$neg৳${_d(trim(v / 100000))}${bn ? ' লাখ' : 'L'}';
    if (v >= 10000) return '$neg৳${_d(trim(v / 1000))}${bn ? ' হা.' : 'K'}';
    return '$neg৳${number(v)}';
  }

  String percent(double ratio) => '${_d((ratio * 100).round().toString())}%';

  static const _bnMonths = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
  static const _bnMonthsShort = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রি', 'মে', 'জুন', 'জুলা', 'আগ', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
  static const _enMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _enMonthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _bnWeekdays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
  static const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String month(int m) => bn ? _bnMonths[m - 1] : _enMonths[m - 1];
  String monthShort(int m) => bn ? _bnMonthsShort[m - 1] : _enMonthsShort[m - 1];
  String weekday(DateTime d) => bn ? _bnWeekdays[d.weekday - 1] : _enWeekdays[d.weekday - 1];

  /// "7 Oct"
  String dayMonth(DateTime d) => '${_d('${d.day}')} ${monthShort(d.month)}';

  /// "7 Oct 2026"
  String date(DateTime d) => '${_d('${d.day}')} ${monthShort(d.month)} ${_d('${d.year}')}';

  /// "October 2026"
  String monthYear(DateTime d) => '${month(d.month)} ${_d('${d.year}')}';

  /// Today / Yesterday / Wed, 7 Oct
  String relativeDay(DateTime d, S s) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(d);
    final diff = today.difference(day).inDays;
    if (diff == 0) return s.today;
    if (diff == 1) return s.yesterday;
    return '${weekday(d)}, ${dayMonth(d)}';
  }

  String digits(Object v) => _d(v.toString());
}

extension FmtX on BuildContext {
  Fmt get fmt => Fmt.of(this);
  S get s => S.of(this);
}

/// Storage format for dates (sortable, timezone-free).
String dbDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDbDate(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}
