import 'package:controle_clinica/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum FieldType {
  text,
  email,
  phone,
  date, // data de nascimento: só aceita datas até hoje
  dateAny, // data livre (ex.: data de um agendamento)
  time, // horário HH:mm
  dropdown,
  CPF,
  money,
  password,
  multiline,
  integer, // número inteiro (ex.: minutos)
}

class FormFieldConfig {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;

  /// Texto exibido para cada opção do dropdown (valor -> rótulo).
  /// Se omitido, o próprio valor é exibido.
  final Map<String, String>? optionLabels;
  final dynamic initialValue;

  /// Primeira data que o seletor deixa escolher (só para [FieldType.dateAny]).
  /// Ex.: hoje, para não permitir agendamentos em dias que já passaram.
  final DateTime? firstDate;

  /// Chamado quando o usuário muda este campo (dropdown, data ou horário).
  /// [values] são os valores atuais do formulário; [setText] altera o texto
  /// de outro campo de data/horário/texto, ou o valor de um dropdown (ex.:
  /// sugerir o horário final ou a sala).
  final void Function(
    Map<String, dynamic> values,
    void Function(String field, String text) setText,
  )?
  onChanged;

  const FormFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.optionLabels,
    this.initialValue,
    this.firstDate,
    this.onChanged,
  });
}

class EntityFormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const EntityFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  @override
  State<EntityFormDialog> createState() => _EntityFormDialogState();
}

class _EntityFormDialogState extends State<EntityFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _values = {};

  // Criados uma única vez: se fossem recriados no build, o texto digitado
  // seria apagado a cada rebuild (por exemplo, após um erro ao salvar).
  final Map<String, TextEditingController> _controllers = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    for (final field in widget.fields) {
      _values[field.name] = field.initialValue;

      if (field.type != FieldType.dropdown) {
        _controllers[field.name] = TextEditingController(
          text: _displayText(field),
        );
      }
    }
  }

  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Texto mostrado no campo. Datas guardadas como yyyy-MM-dd aparecem como
  /// dd/MM/yyyy, igual ao que o seletor de data escreve.
  String _displayText(FormFieldConfig field) {
    final initial = field.initialValue?.toString() ?? "";

    if (field.type == FieldType.CPF) return formatCpf(initial);
    if (field.type == FieldType.phone) return formatPhone(initial);

    if ((field.type == FieldType.date || field.type == FieldType.dateAny) &&
        _isoDate.hasMatch(initial)) {
      final parts = initial.split('-');
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    }

    return initial;
  }

  DateTime? _parseIsoDate(dynamic value) {
    final text = value?.toString() ?? "";

    if (!_isoDate.hasMatch(text)) return null;

    return DateTime.tryParse(text);
  }

  TimeOfDay? _parseTime(String? text) {
    final parts = (text ?? "").split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Altera o texto de um campo de data/horário/texto por código.
  void _setText(String name, String text) {
    _values[name] = text;
    _controllers[name]?.text = text;

    // Dropdowns não têm controller: reconstrói para mostrar o novo valor.
    if (_controllers[name] == null && mounted) setState(() {});
  }

  void _notify(FormFieldConfig field) {
    field.onChanged?.call(_values, _setText);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Aparência (fundo, bordas, foco) vem do tema do app.
  InputDecoration _decoration(String label) {
    return InputDecoration(labelText: label);
  }

  String? _validate(FormFieldConfig field, String? value) {
    if (field.required && (value == null || value.trim().isEmpty)) {
      return "Campo obrigatório";
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    switch (field.type) {
      case FieldType.email:
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

        if (!emailRegex.hasMatch(value)) {
          return "Email inválido";
        }
        break;

      case FieldType.phone:
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

        if (digits.length < 10) {
          return "Telefone inválido";
        }
        break;

      case FieldType.CPF:
        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

        if (digits.length != 11) {
          return "CPF inválido";
        }
        break;

      case FieldType.money:
        final amount = double.tryParse(value.replaceAll(',', '.'));

        if (amount == null || amount < 0) {
          return "Valor inválido";
        }
        break;

      case FieldType.integer:
        final number = int.tryParse(value);

        if (number == null || number <= 0) {
          return "Número inválido";
        }
        break;

      case FieldType.password:
        if (value.length < 8) {
          return "A senha deve ter pelo menos 8 caracteres";
        }
        break;

      default:
        break;
    }

    return null;
  }

  TextInputType _keyboardFor(FieldType type) {
    switch (type) {
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.CPF:
        return TextInputType.number;
      case FieldType.integer:
        return TextInputType.number;
      case FieldType.money:
        return const TextInputType.numberWithOptions(decimal: true);
      case FieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  dynamic _parseValue(FormFieldConfig field, String? value) {
    // CPF e telefone aparecem formatados, mas a API recebe só os dígitos.
    if (field.type == FieldType.CPF || field.type == FieldType.phone) {
      return onlyDigits(value);
    }
    if (field.type == FieldType.money) {
      return double.tryParse((value ?? "").replaceAll(',', '.')) ?? 0;
    }
    if (field.type == FieldType.integer) {
      return int.tryParse((value ?? "").trim()) ?? 0;
    }
    return value;
  }

  Widget _buildField(FormFieldConfig field) {
    switch (field.type) {
      case FieldType.date:
      case FieldType.dateAny:
        final controller = _controllers[field.name]!;
        final anyDate = field.type == FieldType.dateAny;

        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: _decoration(
            field.label,
          ).copyWith(suffixIcon: const Icon(Icons.calendar_month)),
          validator: (value) => _validate(field, value),
          onTap: () async {
            final now = DateTime.now();
            final firstDate =
                anyDate ? (field.firstDate ?? DateTime(2000)) : DateTime(1900);
            final lastDate = anyDate ? DateTime(2100) : now;
            var initialDate = _parseIsoDate(_values[field.name]) ?? now;

            if (initialDate.isBefore(firstDate)) initialDate = firstDate;
            if (initialDate.isAfter(lastDate)) initialDate = lastDate;

            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
            );

            if (date != null) {
              controller.text = DateFormat('dd/MM/yyyy').format(date);

              _values[field.name] = DateFormat('yyyy-MM-dd').format(date);

              _notify(field);
            }
          },
        );

      case FieldType.time:
        final controller = _controllers[field.name]!;

        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: _decoration(
            field.label,
          ).copyWith(suffixIcon: const Icon(Icons.access_time)),
          validator: (value) => _validate(field, value),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
              builder:
                  (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
            );

            if (picked != null) {
              final text =
                  "${picked.hour.toString().padLeft(2, '0')}:"
                  "${picked.minute.toString().padLeft(2, '0')}";

              controller.text = text;
              _values[field.name] = text;

              _notify(field);
            }
          },
        );

      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          // A chave acompanha o valor atual: quando o código muda o valor
          // (setText), o dropdown é recriado já com a nova seleção.
          key: ValueKey("${field.name}:${_values[field.name]}"),
          isExpanded: true,
          initialValue: _values[field.name]?.toString(),
          decoration: _decoration(field.label),
          items:
              field.options!
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(field.optionLabels?[option] ?? option),
                    ),
                  )
                  .toList(),
          validator: (value) {
            if (field.required && value == null) {
              return "Campo obrigatório";
            }

            return null;
          },
          onChanged: (value) {
            _values[field.name] = value;

            _notify(field);
          },
        );

      case FieldType.text:
      case FieldType.email:
      case FieldType.phone:
      case FieldType.CPF:
      case FieldType.money:
      case FieldType.integer:
      case FieldType.password:
      case FieldType.multiline:
        return TextFormField(
          controller: _controllers[field.name],
          keyboardType: _keyboardFor(field.type),
          inputFormatters:
              field.type == FieldType.CPF
                  ? [cpfMask]
                  : field.type == FieldType.phone
                  ? [phoneMask]
                  : null,
          obscureText: field.type == FieldType.password,
          minLines: field.type == FieldType.multiline ? 3 : 1,
          maxLines: field.type == FieldType.multiline ? 5 : 1,
          decoration: _decoration(field.label).copyWith(
            prefixText: field.type == FieldType.money ? 'R\$ ' : null,
          ),
          validator: (value) => _validate(field, value),
          onChanged: (_) => _notify(field),
          onSaved: (value) => _values[field.name] = _parseValue(field, value),
        );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSubmit(_values);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  widget.fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildField(field),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Salvar"),
        ),
      ],
    );
  }
}
