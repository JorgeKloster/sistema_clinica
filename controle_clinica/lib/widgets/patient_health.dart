import 'package:controle_clinica/services/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Itens de um campo de saúde (a API guarda um item por linha).
List<String> healthItems(dynamic text) {
  return (text ?? "")
      .toString()
      .split("\n")
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

/// Texto "Última alteração: 14/11/2026 17:30 por Fulano".
String healthLastChange(Map<String, dynamic> patient) {
  final raw = (patient["health_updated_at"] ?? "").toString();

  if (raw.isEmpty) return "Ainda não preenchido";

  final date = DateTime.tryParse(raw);
  final by = (patient["health_updated_by_name"] ?? "").toString();

  if (date == null) return "Ainda não preenchido";

  return "Última alteração: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}"
      "${by.isEmpty ? "" : " por $by"}";
}

/// Alergias, condições de saúde e medicamentos em listas com marcadores.
/// Só exibe; [onEdit] (opcional) mostra o botão de edição.
class PatientHealthView extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback? onEdit;

  const PatientHealthView({super.key, required this.patient, this.onEdit});

  Widget _section(String title, IconData icon, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 24),
              child: Text("Nada registrado", style: TextStyle(color: Colors.black54)),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("•  "),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          "Alergias",
          Icons.warning_amber_rounded,
          healthItems(patient["allergies"]),
        ),
        _section(
          "Condições de saúde",
          Icons.monitor_heart_outlined,
          healthItems(patient["medical_conditions"]),
        ),
        _section(
          "Medicamentos em uso",
          Icons.medication_outlined,
          healthItems(patient["medications"]),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                healthLastChange(patient),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            if (onEdit != null)
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text("Editar"),
              ),
          ],
        ),
      ],
    );
  }
}

/// Abre o editor das informações de saúde. Devolve true se salvou.
Future<bool> showPatientHealthDialog(
  BuildContext context,
  Map<String, dynamic> patient,
) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _PatientHealthDialog(patient: patient),
  );

  return saved ?? false;
}

class _PatientHealthDialog extends StatefulWidget {
  final Map<String, dynamic> patient;

  const _PatientHealthDialog({required this.patient});

  @override
  State<_PatientHealthDialog> createState() => _PatientHealthDialogState();
}

class _PatientHealthDialogState extends State<_PatientHealthDialog> {
  late final List<String> _allergies = healthItems(widget.patient["allergies"]);
  late final List<String> _conditions = healthItems(
    widget.patient["medical_conditions"],
  );
  late final List<String> _medications = healthItems(
    widget.patient["medications"],
  );

  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await PatientService.updatePatientHealth(
        widget.patient["patient_id"] as int,
        allergies: _allergies,
        conditions: _conditions,
        medications: _medications,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Informações de saúde"),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemsEditor(
                title: "Alergias",
                hint: "Ex.: Dipirona, látex, penicilina",
                items: _allergies,
                onChanged: () => setState(() {}),
              ),
              _ItemsEditor(
                title: "Condições de saúde",
                hint: "Ex.: Diabetes, hipertensão, gestante",
                items: _conditions,
                onChanged: () => setState(() {}),
              ),
              _ItemsEditor(
                title: "Medicamentos em uso",
                hint: "Ex.: Losartana 50 mg",
                items: _medications,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
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

/// Lista editável: adiciona um item por vez e remove com o "x".
class _ItemsEditor extends StatefulWidget {
  final String title;
  final String hint;
  final List<String> items;
  final VoidCallback onChanged;

  const _ItemsEditor({
    required this.title,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_ItemsEditor> createState() => _ItemsEditorState();
}

class _ItemsEditorState extends State<_ItemsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    // Um item por linha: quebras de linha viram itens separados.
    final parts =
        text.split("\n").map((part) => part.trim()).where((p) => p.isNotEmpty);

    for (final part in parts) {
      if (!widget.items.contains(part)) widget.items.add(part);
    }

    _controller.clear();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (widget.items.isEmpty)
            const Text("Nada registrado", style: TextStyle(color: Colors.black54))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in widget.items)
                  InputChip(
                    label: Text(item),
                    onDeleted: () {
                      widget.items.remove(item);
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            onSubmitted: (_) => _add(),
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                tooltip: "Adicionar",
                icon: const Icon(Icons.add),
                onPressed: _add,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
