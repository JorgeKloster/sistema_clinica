import 'package:flutter/material.dart';

enum FieldType { text, email, phone, date, dropdown, CPF }

class FormFieldConfig {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;

  const FormFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
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

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
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

      default:
        break;
    }

    return null;
  }

  Widget _buildField(FormFieldConfig field) {
    switch (field.type) {
      case FieldType.text:
        return TextFormField(
          decoration: _decoration(field.label),
          validator: (value) => _validate(field, value),
          onSaved: (value) => _values[field.name] = value,
        );

      case FieldType.email:
        return TextFormField(
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration(field.label),
          validator: (value) => _validate(field, value),
          onSaved: (value) => _values[field.name] = value,
        );

      case FieldType.phone:
        return TextFormField(
          keyboardType: TextInputType.phone,
          decoration: _decoration(field.label),
          validator: (value) => _validate(field, value),
          onSaved: (value) => _values[field.name] = value,
        );

      case FieldType.date:
        final controller = TextEditingController();

        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: _decoration(
            field.label,
          ).copyWith(suffixIcon: const Icon(Icons.calendar_month)),
          validator: (value) => _validate(field, value),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (date != null) {
              controller.text = "${date.day}/${date.month}/${date.year}";

              _values[field.name] = date.toIso8601String();
            }
          },
        );

      case FieldType.dropdown:
        return DropdownButtonFormField<String>(
          decoration: _decoration(field.label),
          items:
              field.options!
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
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
          },
        );
      case FieldType.CPF:
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: _decoration(field.label),
          validator: (value) => _validate(field, value),
          onSaved: (value) => _values[field.name] = value,
        );
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

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
            }
          },
          child: const Text("Salvar"),
        ),
      ],
    );
  }
}
