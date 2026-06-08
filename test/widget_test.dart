import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ecopoin_app/core/utils/formatters.dart';
import 'package:ecopoin_app/core/utils/validators.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Formatters', () {
    test('GreenCoin to Rupiah conversion', () {
      expect(Formatters.rupiahFromGc(100), 10000);
      expect(Formatters.gcFromRupiah(10000), 100);
    });

    test('GreenCoin formatting', () {
      expect(Formatters.greenCoin(2500), contains('GC'));
    });

    test('Weight formatting handles integers and decimals', () {
      expect(Formatters.weight(45), '45 kg');
      expect(Formatters.weight(3.5), '3,5 kg');
      // Decimal uses a comma so the dashboard count-up parser doesn't read
      // "7.1" as "71" (dot = thousands separator there).
      expect(Formatters.weight(7.14), '7,1 kg');
    });
  });

  group('Validators', () {
    test('Email validator rejects malformed emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
    });

    test('Password requires 8 characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });

    test('Phone validator accepts Indonesian formats', () {
      expect(Validators.phone('08123456789'), isNull);
      expect(Validators.phone('+6281234567890'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });
}
