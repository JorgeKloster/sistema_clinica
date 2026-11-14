import 'package:controle_clinica/services/room_service.dart';
import 'package:flutter/material.dart';

/// Diálogo para o administrador ver, adicionar e remover os tipos de sala
/// usados pelas salas da clínica.
class RoomTypesDialog extends StatefulWidget {
  const RoomTypesDialog({super.key});

  @override
  State<RoomTypesDialog> createState() => _RoomTypesDialogState();
}

class _RoomTypesDialogState extends State<RoomTypesDialog> {
  final _controller = TextEditingController();

  List<dynamic> _types = [];
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
      final data = await RoomService.getRoomTypes();

      if (!mounted) return;

      setState(() {
        _types = data;
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
      await RoomService.createRoomType(name);
      _controller.clear();
      await _load();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _remove(Map<String, dynamic> roomType) async {
    try {
      await RoomService.deleteRoomType(roomType["room_type_id"]);
      await _load();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Tipos de sala"),
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
                      hintText: "Novo tipo (ex.: Sala de ultrassom)",
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
                      : _types.isEmpty
                      ? const Center(
                        child: Text("Nenhum tipo de sala cadastrado"),
                      )
                      : ListView.separated(
                        itemCount: _types.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final roomType = _types[index];

                          return ListTile(
                            dense: true,
                            title: Text("${roomType["name"]}"),
                            trailing: IconButton(
                              tooltip: "Excluir",
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _remove(roomType),
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
