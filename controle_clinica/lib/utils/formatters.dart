import 'package:flutter/services.dart';

/// Formatação de CPF e telefone apenas para exibição/digitação.
/// O valor enviado à API continua sendo só os dígitos.

String onlyDigits(String? value) =>
    (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

/// 12345678901 -> 123.456.789-01
String formatCpf(String? value) {
  final d = onlyDigits(value);
  if (d.length != 11) return value ?? '';
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.'
      '${d.substring(6, 9)}-${d.substring(9)}';
}

/// 11987654321 -> (11) 98765-4321  |  1134567890 -> (11) 3456-7890
String formatPhone(String? value) {
  final d = onlyDigits(value);
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return value ?? '';
}

/// Máscara aplicada enquanto o usuário digita.
class MaskFormatter extends TextInputFormatter {
  final String Function(String digits) format;
  final int maxDigits;

  MaskFormatter(this.format, this.maxDigits);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = onlyDigits(newValue.text);
    if (d.length > maxDigits) d = d.substring(0, maxDigits);

    final text = format(d);

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String _partialCpf(String d) {
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 3 || i == 6) b.write('.');
    if (i == 9) b.write('-');
    b.write(d[i]);
  }
  return b.toString();
}

String _partialPhone(String d) {
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';

  final ddd = d.substring(0, 2);
  final rest = d.substring(2);
  final cut = d.length == 11 ? 5 : 4;

  if (rest.length <= cut) return '($ddd) $rest';
  return '($ddd) ${rest.substring(0, cut)}-${rest.substring(cut)}';
}

final cpfMask = MaskFormatter(_partialCpf, 11);
final phoneMask = MaskFormatter(_partialPhone, 11);
