import 'package:controle_clinica/services/specialty_service.dart';
import 'package:flutter/material.dart';

/// Diálogo para o administrador ver, adicionar e remover as especialidades
/// oferecidas pela clínica.
class SpecialtiesDialog extends StatefulWidget {
  const SpecialtiesDialog({super.key});

  @override
  State<SpecialtiesDialog> createState() => _SpecialtiesDialogState();
}

class _SpecialtiesDialogState extends State<SpecialtiesDialog> {
  final _controller = TextEditingController();

  List<dynamic> _specialties = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    try {
      final data = await SpecialtyService.getSpecialties();

      if (!mounted) return;

      setState(() {
        _specialties = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage(e.toString());
    }
  }

  Future<void> _add() async {
    final name = _controller.text.trim();

    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await SpecialtyService.createSpecialty(name);
      _controller.clear();
      await _load();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _remove(Map<String, dynamic> specialty) async {
    try {
      await SpecialtyService.deleteSpecialty(specialty["specialty_id"]);
      await _load();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Especialidades da clínica"),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Nova especialidade (ex.: Ortodontista)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: "Adicionar",
                  onPressed: _isSaving ? null : _add,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _specialties.isEmpty
                      ? const Center(
                        child: Text("Nenhuma especialidade cadastrada"),
                      )
                      : ListView.separated(
                        itemCount: _specialties.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final specialty = _specialties[index];

                          return ListTile(
                            dense: true,
                            title: Text("${specialty["name"]}"),
                            trailing: IconButton(
                              tooltip: "Excluir",
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _remove(specialty),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Fechar"),
        ),
      ],
    );
  }
}
