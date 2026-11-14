import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/procedure_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProceduresPage extends StatefulWidget {
  const ProceduresPage({super.key});

  @override
  State<ProceduresPage> createState() => _ProceduresPageState();
}

class _ProceduresPageState extends State<ProceduresPage> {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );

  List<dynamic> procedures = [];
  List<dynamic> filteredProcedures = [];
  String _query = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProcedures();
  }

  Future<void> _loadProcedures() async {
    try {
      final data = await ProcedureService.getProcedures();

      if (!mounted) return;

      setState(() {
        procedures = data;
        isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage("Erro ao carregar procedimentos: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _filterProcedures(String query) {
    _query = query;
    _applyFilter();
  }

  void _applyFilter() {
    final search = _query.toLowerCase().trim();

    setState(() {
      filteredProcedures =
          procedures.where((p) {
            final name = (p["name"] ?? "").toString().toLowerCase();
            final description =
                (p["description"] ?? "").toString().toLowerCase();

            return name.contains(search) || description.contains(search);
          }).toList();
    });
  }

  double _priceOf(Map<String, dynamic> procedure) =>
      (procedure["price"] as num?)?.toDouble() ?? 0;

  List<FormFieldConfig> _fields({Map<String, dynamic>? procedure}) {
    return [
      FormFieldConfig(
        name: "name",
        label: "Nome",
        type: FieldType.text,
        required: true,
        initialValue: procedure?["name"],
      ),
      FormFieldConfig(
        name: "description",
        label: "Descrição",
        type: FieldType.text,
        initialValue: procedure?["description"],
      ),
      FormFieldConfig(
        name: "price",
        label: "Valor",
        type: FieldType.money,
        required: true,
        initialValue:
            procedure == null ? null : _priceOf(procedure).toStringAsFixed(2),
      ),
    ];
  }

  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Adicionar Procedimento",
            fields: _fields(),
            onSubmit: (values) async {
              await ProcedureService.createProcedure(values);

              await _loadProcedures();

              if (mounted) {
                _showMessage("Procedimento cadastrado com sucesso");
              }
            },
          ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> procedure) async {
    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Editar Procedimento",
            fields: _fields(procedure: procedure),
            onSubmit: (values) async {
              await ProcedureService.updateProcedure(
                procedure["procedure_id"],
                values,
              );

              await _loadProcedures();

              if (mounted) {
                _showMessage("Procedimento atualizado com sucesso");
              }
            },
          ),
    );
  }

  Future<void> _delete(Map<String, dynamic> procedure) async {
    final confirm = await showConfirmationDialog(
      context,
      title: "Excluir procedimento",
      message: "Deseja realmente excluir o procedimento ${procedure["name"]}?",
    );

    if (confirm != true) return;

    try {
      await ProcedureService.deleteProcedure(procedure["procedure_id"]);

      await _loadProcedures();

      if (mounted) {
        _showMessage("Procedimento excluído com sucesso");
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Procedimentos",
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Pesquisar por nome ou descrição",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _filterProcedures,
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : procedures.isEmpty
                        ? _buildEmpty()
                        : filteredProcedures.isEmpty
                        ? _buildNoSearchResults()
                        : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredProcedures.length,
                          itemBuilder: (context, index) {
                            return _buildCard(filteredProcedures[index]);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> procedure) {
    final description = (procedure["description"] ?? "").toString();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.medical_services)),
        title: Text("${procedure["name"]}"),
        subtitle: description.isEmpty ? null : Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currency.format(_priceOf(procedure)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'Editar':
                    await _showEditDialog(procedure);
                    break;

                  case 'Excluir':
                    await _delete(procedure);
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
}

Widget _buildEmpty() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.medical_services_outlined,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          "Nenhum procedimento cadastrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Cadastre o primeiro procedimento da clínica.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

Widget _buildNoSearchResults() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          "Nenhum procedimento encontrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Tente pesquisar por outro nome ou descrição.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}
