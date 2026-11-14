import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/services/professional_service.dart';
import 'package:controle_clinica/services/specialty_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:controle_clinica/widgets/specialties_dialog.dart';
import 'package:flutter/material.dart';

/// Valores gravados no banco (users.role) -> texto exibido.
const Map<String, String> _roleLabels = {
  "admin": "Administrador",
  "doctor": "Profissional de saúde",
  "receptionist": "Recepcionista",
};

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  List<dynamic> professionals = [];
  List<dynamic> filteredProfessionals = [];
  List<String> _specialties = [];
  String _query = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final data = await SpecialtyService.getSpecialties();

      if (!mounted) return;

      setState(() {
        _specialties = data.map((s) => s["name"].toString()).toList();
      });
    } catch (e) {
      if (mounted) _showMessage("Erro ao carregar especialidades: $e");
    }
  }

  Future<void> _manageSpecialties() async {
    await showDialog(
      context: context,
      builder: (_) => const SpecialtiesDialog(),
    );

    await _loadSpecialties();
  }

  Future<void> _loadProfessionals() async {
    try {
      final data = await ProfessionalService.getProfessionals();

      if (!mounted) return;

      setState(() {
        professionals = data;
        isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage("Erro ao carregar profissionais: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _filterProfessionals(String query) {
    _query = query;
    _applyFilter();
  }

  void _applyFilter() {
    final search = _query.toLowerCase().trim();
    final searchDigits = search.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      filteredProfessionals =
          professionals.where((p) {
            final fullName =
                "${p["first_name"] ?? ""} ${p["last_name"] ?? ""}"
                    .toLowerCase();
            final email = (p["email"] ?? "").toString().toLowerCase();
            final specialty = (p["specialty"] ?? "").toString().toLowerCase();
            final phone = (p["phone"] ?? "").toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            return fullName.contains(search) ||
                email.contains(search) ||
                specialty.contains(search) ||
                (searchDigits.isNotEmpty && phone.contains(searchDigits));
          }).toList();
    });
  }

  List<FormFieldConfig> _fields({Map<String, dynamic>? professional}) {
    final isEditing = professional != null;

    // Se a especialidade atual não estiver mais na lista da clínica, mantém
    // como opção para o dropdown não quebrar na edição.
    final currentSpecialty = (professional?["specialty"] ?? "").toString();
    final specialtyOptions = [
      ..._specialties,
      if (currentSpecialty.isNotEmpty && !_specialties.contains(currentSpecialty))
        currentSpecialty,
    ];

    return [
      FormFieldConfig(
        name: "first_name",
        label: "Nome",
        type: FieldType.text,
        required: true,
        initialValue: professional?["first_name"],
      ),
      FormFieldConfig(
        name: "last_name",
        label: "Sobrenome",
        type: FieldType.text,
        required: true,
        initialValue: professional?["last_name"],
      ),
      FormFieldConfig(
        name: "email",
        label: "Email",
        type: FieldType.email,
        required: true,
        initialValue: professional?["email"],
      ),
      FormFieldConfig(
        name: "phone",
        label: "Telefone",
        type: FieldType.phone,
        initialValue: professional?["phone"],
      ),
      FormFieldConfig(
        name: "role",
        label: "Perfil de acesso",
        type: FieldType.dropdown,
        required: true,
        options: _roleLabels.keys.toList(),
        optionLabels: _roleLabels,
        initialValue: professional?["role"],
      ),
      FormFieldConfig(
        name: "specialty",
        label: "Especialidade (obrigatória para profissional de saúde)",
        type: FieldType.dropdown,
        options: specialtyOptions,
        initialValue: currentSpecialty.isEmpty ? null : currentSpecialty,
      ),
      FormFieldConfig(
        name: "password",
        label: isEditing ? "Nova senha (deixe em branco para manter)" : "Senha",
        type: FieldType.password,
        required: !isEditing,
      ),
    ];
  }

  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Adicionar Profissional",
            fields: _fields(),
            onSubmit: (values) async {
              await ProfessionalService.createProfessional(values);

              await _loadProfessionals();

              if (mounted) {
                _showMessage("Profissional cadastrado com sucesso");
              }
            },
          ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> professional) async {
    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: "Editar Profissional",
            fields: _fields(professional: professional),
            onSubmit: (values) async {
              await ProfessionalService.updateProfessional(
                professional["user_id"],
                values,
              );

              await _loadProfessionals();

              if (mounted) {
                _showMessage("Profissional atualizado com sucesso");
              }
            },
          ),
    );
  }

  Future<void> _delete(Map<String, dynamic> professional) async {
    if (professional["user_id"] == AuthService().userId) {
      _showMessage("Você não pode excluir o próprio usuário");
      return;
    }

    final confirm = await showConfirmationDialog(
      context,
      title: "Excluir profissional",
      message:
          "Deseja realmente excluir "
          "${professional["first_name"]} ${professional["last_name"]}?",
    );

    if (confirm != true) return;

    try {
      await ProfessionalService.deleteProfessional(professional["user_id"]);

      await _loadProfessionals();

      if (mounted) {
        _showMessage("Profissional excluído com sucesso");
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
      title: "Profissionais",
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              "Pesquisar por nome, email, telefone ou especialidade",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: _filterProfessionals,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _manageSpecialties,
                      icon: const Icon(Icons.local_hospital_outlined),
                      label: const Text("Especialidades"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : professionals.isEmpty
                        ? _buildEmpty()
                        : filteredProfessionals.isEmpty
                        ? _buildNoSearchResults()
                        : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredProfessionals.length,
                          itemBuilder: (context, index) {
                            final professional = filteredProfessionals[index];

                            return _buildCard(professional);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> professional) {
    final firstName = professional["first_name"] ?? "";
    final lastName = professional["last_name"] ?? "";
    final role = _roleLabels[professional["role"]] ?? professional["role"];
    final specialty = (professional["specialty"] ?? "").toString();
    final phone = (professional["phone"] ?? "").toString();

    final line1 = specialty.isEmpty ? "$role" : "$role • $specialty";
    final line2 =
        phone.isEmpty ? "${professional["email"]}" : "${professional["email"]} • $phone";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(firstName.isEmpty ? "?" : firstName[0]),
        ),
        title: Text("$firstName $lastName"),
        subtitle: Text("$line1\n$line2"),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'Editar':
                await _showEditDialog(professional);
                break;

              case 'Excluir':
                await _delete(professional);
                break;
            }
          },
          itemBuilder:
              (context) => const [
                PopupMenuItem(value: 'Editar', child: Text("Editar")),
                PopupMenuItem(value: 'Excluir', child: Text("Excluir")),
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
        Icon(Icons.badge_outlined, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          "Nenhum profissional cadastrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Cadastre o primeiro profissional da clínica.",
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
        Icon(Icons.person_search, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          "Nenhum profissional encontrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Tente pesquisar por outro nome, email ou especialidade.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}
