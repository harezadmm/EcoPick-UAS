import 'package:intl/intl.dart';
import '../constants/app_strings.dart';

class Formatters {
  Formatters._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _number = NumberFormat.decimalPattern('id_ID');

  static String rupiah(num value) => _rupiah.format(value);

  static String greenCoin(num value) => '${_number.format(value)} GC';

  static String greenCoinCompact(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M GC';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K GC';
    } else {
      return '${value.toInt()} GC';
    }
  }

  static String weight(num value) {
    if (value == value.truncate()) return '${value.toInt()} kg';
    // Use a comma as the decimal separator (id_ID) so it matches how the
    // dashboard's count-up parser reads numbers (dot = thousands, comma =
    // decimal). Returning a dot here makes "7.1" parse as "71".
    return '${value.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  static String compactNumber(num value) => _number.format(value);

  static String date(DateTime value) =>
      DateFormat('d MMM yyyy', 'id_ID').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(value);

  static String dayShort(DateTime value) =>
      DateFormat('EEE', 'id_ID').format(value);

  static int rupiahFromGc(num gc) => (gc * AppStrings.gcToRupiahRate).round();

  static int gcFromRupiah(num rupiah) =>
      (rupiah / AppStrings.gcToRupiahRate).round();
}
