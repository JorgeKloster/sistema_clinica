import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/patient_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:flutter/material.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<dynamic> patients = [];
  List<dynamic> filteredPatients = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final data = await PatientService.getPatients();

      setState(() {
        patients = data;
        filteredPatients = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar pacientes: $e")),
        );
      }
    }
  }

  void _filterPatients(String query) {
    final search = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    setState(() {
      filteredPatients =
          patients.where((patient) {
            final firstName =
                (patient["first_name"] ?? "").toString().toLowerCase();

            final lastName =
                (patient["last_name"] ?? "").toString().toLowerCase();

            final fullName = "$firstName $lastName";

            final cpf = (patient["cpf"] ?? "").toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            final phone = (patient["phone"] ?? "").toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            return fullName.contains(search) ||
                firstName.contains(search) ||
                lastName.contains(search) ||
                cpf.contains(search) ||
                phone.contains(search);
          }).toList();

      filteredPatients.sort((a, b) {
        final aName = "${a["first_name"]} ${a["last_name"]}";

        final bName = "${b["first_name"]} ${b["last_name"]}";

        return aName.compareTo(bName);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Pacientes",
      userRole: "dentist",
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (_) => EntityFormDialog(
                  title: "Adicionar Paciente",
                  fields: [
                    FormFieldConfig(
                      name: "first_name",
                      label: "Nome",
                      type: FieldType.text,
                      required: true,
                    ),
                    FormFieldConfig(
                      name: "last_name",
                      label: "Sobrenome",
                      type: FieldType.text,
                      required: true,
                    ),
                    FormFieldConfig(
                      name: "cpf",
                      label: "CPF",
                      type: FieldType.CPF,
                      required: true,
                    ),
                    FormFieldConfig(
                      name: "birth_date",
                      label: "Data de nascimento",
                      type: FieldType.date,
                      required: true,
                    ),
                    FormFieldConfig(
                      name: "gender",
                      label: "Sexo",
                      type: FieldType.dropdown,
                      required: true,
                      options: ["Masculino", "Feminino"],
                    ),
                    FormFieldConfig(
                      name: "phone",
                      label: "Telefone",
                      type: FieldType.phone,
                    ),
                    FormFieldConfig(
                      name: "email",
                      label: "Email",
                      type: FieldType.email,
                    ),
                  ],
                  onSubmit: (values) async {
                    await PatientService.createPatient(values);

                    await _loadPatients();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Paciente cadastrado com sucesso"),
                        ),
                      );
                    }
                  },
                ),
          );
        },
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
                    hintText: "Pesquisar por nome, CPF ou telefone",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _filterPatients,
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        // No patients in the clinic
                        : patients.isEmpty
                        ? _buildEmptyClinic()
                        // Search returned nothing
                        : filteredPatients.isEmpty
                        ? _buildNoSearchResults()
                        // Normal list
                        : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final patient = filteredPatients[index];

                            final firstName = patient["first_name"];
                            final lastName = patient["last_name"];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(patient["first_name"][0]),
                                ),
                                title: Text("$firstName $lastName"),
                                subtitle: Text(
                                  "${patient["cpf"]}\n${patient["phone"]}",
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'Agendar':
                                        Navigator.pushNamed(
                                          context,
                                          '/schedule_procedure',
                                        );
                                        break;

                                      case 'Editar':
                                        break;

                                      case 'Excluir':
                                        final confirm =
                                            await showConfirmationDialog(
                                              context,
                                              title: "Excluir paciente",
                                              message:
                                                  "Deseja realmente excluir este paciente?",
                                            );
                                        if (confirm == true) {
                                          await PatientService.deletePatient(
                                            patient["patient_id"],
                                          );

                                          await _loadPatients();
                                        }

                                        break;
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'Agendar',
                                          child: Text("Agendar procedimento"),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Editar',
                                          child: Text("Editar"),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Excluir',
                                          child: Text("Excluir"),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyClinic() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text(
          "Nenhum paciente cadastrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Cadastre o primeiro paciente da clínica.",
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
          "Nenhum paciente encontrado",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          "Tente pesquisar por outro nome, CPF ou telefone.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}
