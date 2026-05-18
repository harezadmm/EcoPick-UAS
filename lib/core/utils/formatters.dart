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

  static String weight(num value) {
    if (value == value.truncate()) return '${value.toInt()} kg';
    return '${value.toStringAsFixed(1)} kg';
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
