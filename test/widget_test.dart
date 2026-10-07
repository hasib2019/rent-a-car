import 'package:flutter_test/flutter_test.dart';
import 'package:gari_khata/core/format.dart';
import 'package:gari_khata/core/l10n.dart';
import 'package:gari_khata/ui/widgets/common.dart';

void main() {
  group('Fmt', () {
    const en = Fmt(bn: false, bnNum: false);
    const bn = Fmt(bn: true, bnNum: true);

    test('uses lakh grouping', () {
      expect(en.number(999), '999');
      expect(en.number(1000), '1,000');
      expect(en.number(125000), '1,25,000');
      expect(en.number(16500000), '1,65,00,000');
      expect(en.number(-4500), '-4,500');
    });

    test('formats money with taka sign', () {
      expect(en.money(1100), '৳1,100');
      expect(en.money(-200), '−৳200');
      expect(en.money(300, sign: true), '+৳300');
    });

    test('converts to Bangla numerals', () {
      expect(bn.number(125000), '১,২৫,০০০');
      expect(toBnDigits('2026-10-07'), '২০২৬-১০-০৭');
    });

    test('compact amounts', () {
      expect(en.compact(1650000), '৳16.5L');
      expect(en.compact(25000), '৳25K');
      expect(bn.compact(1650000), '৳১৬.৫ লাখ');
    });
  });

  test('parseAmount accepts Bangla digits and commas', () {
    expect(parseAmount('১,২০০'), 1200);
    expect(parseAmount('৳ 3,500'), 3500);
    expect(parseAmount(''), isNull);
    expect(parseAmount('abc'), isNull);
  });

  test('db dates round-trip', () {
    final d = DateTime(2026, 3, 9);
    expect(dbDate(d), '2026-03-09');
    expect(parseDbDate('2026-03-09'), d);
  });
}
