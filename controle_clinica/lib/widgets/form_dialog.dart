import 'package:flutter/material.dart';

class EntityFormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final void Function(Map<String, dynamic>) onSubmit;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // rounded popup itself
      ),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                widget.fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: field.label,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // rounded fields
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      validator: field.validator,
                      onSaved: (val) => _values[field.name] = val,
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSubmit(_values);
              Navigator.pop(context);
            }
          },
          child: const Text("Salvar"),
        ),
      ],
    );
  }
}

class FormFieldConfig {
  final String name;
  final String label;
  final String? Function(String?)? validator;

  FormFieldConfig({required this.name, required this.label, this.validator});
}
