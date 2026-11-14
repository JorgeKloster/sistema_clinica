import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/room_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:controle_clinica/widgets/room_types_dialog.dart';
import 'package:flutter/material.dart';

/// Salas e recursos da clínica. Cada sala tem um tipo (consultório médico,
/// odontológico...) e uma lista de recursos/equipamentos. Os procedimentos
/// são realizados em uma sala, e uma sala não atende dois agendamentos ao
/// mesmo tempo.
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  List<dynamic> rooms = [];
  List<dynamic> filteredRooms = [];
  List<dynamic> roomTypes = [];
  String _query = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        RoomService.getRooms(),
        RoomService.getRoomTypes(),
      ]);

      if (!mounted) return;

      setState(() {
        rooms = results[0];
        roomTypes = results[1];
        isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      _showMessage("Erro ao carregar salas: $e");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _filterRooms(String query) {
    _query = query;
    _applyFilter();
  }

  void _applyFilter() {
    final search = _query.toLowerCase().trim();

    setState(() {
      filteredRooms =
          rooms.where((r) {
            return "${r["name"]} ${r["room_type_name"]} ${r["resources"]}"
                .toLowerCase()
                .contains(search);
          }).toList();
    });
  }

  List<String> _resourcesOf(Map<String, dynamic> room) {
    return (room["resources"] ?? "")
        .toString()
        .split("\n")
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _manageTypes() async {
    await showDialog(context: context, builder: (_) => const RoomTypesDialog());

    await _load();
  }

  List<FormFieldConfig> _fields({Map<String, dynamic>? room}) {
    final typeLabels = {
      for (final t in roomTypes) "${t["room_type_id"]}": "${t["name"]}",
    };

    final currentType = room?["room_type_id"]?.toString();

    return [
      FormFieldConfig(
        name: "name",
        label: "Nome da sala (ex.: Consultório 1)",
        type: FieldType.text,
        required: true,
        initialValue: room?["name"],
      ),
      FormFieldConfig(
        name: "room_type_id",
        label: "Tipo de sala",
        type: FieldType.dropdown,
        required: true,
        options: typeLabels.keys.toList(),
        optionLabels: typeLabels,
        initialValue: typeLabels.containsKey(currentType) ? currentType : null,
      ),
      FormFieldConfig(
        name: "resources",
        label: "Recursos e equipamentos (um por linha)",
        type: FieldType.multiline,
        initialValue: room?["resources"],
      ),
    ];
  }

  Map<String, dynamic> _body(Map<String, dynamic> values) {
    return {
      "name": (values["name"] ?? "").toString().trim(),
      "room_type_id": int.parse(values["room_type_id"].toString()),
      "resources": (values["resources"] ?? "").toString(),
    };
  }

  Future<void> _showCreateDialog() async {
    if (roomTypes.isEmpty) {
      _showMessage("Cadastre ao menos um tipo de sala antes (botão Tipos de sala)");
      return;
    }

    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Adicionar Sala",
            fields: _fields(),
            onSubmit: (values) async {
              await RoomService.createRoom(_body(values));

              await _load();

              _showMessage("Sala cadastrada com sucesso");
            },
          ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> room) async {
    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Editar Sala",
            fields: _fields(room: room),
            onSubmit: (values) async {
              await RoomService.updateRoom(room["room_id"], _body(values));

              await _load();

              _showMessage("Sala atualizada com sucesso");
            },
          ),
    );
  }

  Future<void> _delete(Map<String, dynamic> room) async {
    final confirm = await showConfirmationDialog(
      context,
      title: "Excluir sala",
      message: "Deseja realmente excluir a sala ${room["name"]}?",
    );

    if (!confirm) return;

    try {
      await RoomService.deleteRoom(room["room_id"]);

      await _load();

      _showMessage("Sala excluída com sucesso");
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Widget _buildCard(Map<String, dynamic> room) {
    final resources = _resourcesOf(room);
    final count = (room["procedure_count"] as num?)?.toInt() ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 16),
              child: CircleAvatar(child: Icon(Icons.meeting_room_outlined)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${room["name"]}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text("${room["room_type_name"]}"),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          count == 1 ? "1 procedimento" : "$count procedimentos",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (resources.isEmpty)
                    const Text(
                      "Nenhum recurso cadastrado",
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    for (final item in resources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text("•  $item"),
                      ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'Editar':
                    await _showEditDialog(room);
                    break;

                  case 'Excluir':
                    await _delete(room);
                    break;
                }
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(value: 'Editar', child: Text("Editar")),
                    PopupMenuItem(value: 'Excluir', child: Text("Excluir")),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma sala cadastrada",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Cadastre as salas da clínica para associá-las aos procedimentos.",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Salas e Recursos",
      userRole: "administrator",
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Pesquisar por nome, tipo ou recurso",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _filterRooms,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _manageTypes,
                      icon: const Icon(Icons.category_outlined),
                      label: const Text("Tipos de sala"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : rooms.isEmpty
                        ? _buildEmpty()
                        : filteredRooms.isEmpty
                        ? const Center(child: Text("Nenhuma sala encontrada"))
                        : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredRooms.length,
                          itemBuilder:
                              (context, index) => _buildCard(
                                Map<String, dynamic>.from(
                                  filteredRooms[index] as Map,
                                ),
                              ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
