import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patients = ["Maria Silva", "João Souza", "Ana Costa"];

    return BasePage(
      title: "Pacientes",
      userRole: "dentist",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  title: Text(
                    patient,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'Agendar':
                          Navigator.pushNamed(context, '/schedule_procedure');
                          break;
                        case 'Editar':
                          Navigator.pushNamed(context, '/edit_patient');
                          break;
                        case 'Excluir':
                          // handle delete logic
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (_) => EntityFormDialog(
                  title: "Adicionar Paciente",
                  fields: [
                    FormFieldConfig(name: "name", label: "Nome"),
                    FormFieldConfig(name: "email", label: "Email"),
                    FormFieldConfig(name: "phone", label: "Telefone"),
                  ],
                  onSubmit: (values) {
                    // Save patient logic
                    print(values);
                  },
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
