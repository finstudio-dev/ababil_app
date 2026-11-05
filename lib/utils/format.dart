import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat.currency(symbol: '৳ ', decimalDigits: 2);
final _dateFormat = DateFormat('d MMM y, h:mm a');
final _monthFormat = DateFormat('MMMM y');

String formatMoney(num amount) => _moneyFormat.format(amount);
String formatDate(DateTime date) => _dateFormat.format(date.toLocal());
String formatMonth(DateTime date) => _monthFormat.format(date);
