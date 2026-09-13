import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String userRole;

  const Sidebar({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF41372E), // optional background color
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clinic logo
                Image.asset(
                  'assets/images/bucalle.jpg', // path to your logo in assets
                  height: 120,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ---------------- Administrator ----------------
          if (userRole == "administrator") ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Atendimentos em andamento"),
              onTap:
                  () =>
                      Navigator.pushNamed(context, '/admin_live_consultations'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text("Gerenciamento"),
              children: [
                ListTile(
                  title: const Text("Pacientes"),
                  onTap: () => Navigator.pushNamed(context, '/admin_patients'),
                ),
                ListTile(
                  title: const Text("Profissionais"),
                  onTap:
                      () =>
                          Navigator.pushNamed(context, '/admin_professionals'),
                ),
                ListTile(
                  title: const Text("Procedimentos"),
                  onTap:
                      () => Navigator.pushNamed(context, '/admin_procedures'),
                ),
                ListTile(
                  title: const Text("Salas e Recursos"),
                  onTap: () => Navigator.pushNamed(context, '/admin_resources'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.analytics),
              title: const Text("Relatórios"),
              children: [
                ListTile(
                  title: const Text("Financeiro"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_reports_financial',
                      ),
                ),
                ListTile(
                  title: const Text("Atendimentos"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_reports_appointments',
                      ),
                ),
                ListTile(
                  title: const Text("Estatísticas de Pacientes"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_reports_patients',
                      ),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Administração"),
              children: [
                ListTile(
                  title: const Text("Controle de Acesso"),
                  onTap:
                      () =>
                          Navigator.pushNamed(context, '/admin_access_control'),
                ),
                ListTile(
                  title: const Text("Configurações da Clínica"),
                  onTap: () => Navigator.pushNamed(context, '/admin_settings'),
                ),
                ListTile(
                  title: const Text("Integrações"),
                  onTap:
                      () => Navigator.pushNamed(context, '/admin_integrations'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.message),
              title: const Text("Comunicação"),
              children: [
                ListTile(
                  title: const Text("Mensagens Internas"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_internal_messages',
                      ),
                ),
                ListTile(
                  title: const Text("Notificações aos Pacientes"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_patient_notifications',
                      ),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.description),
              title: const Text("Suporte & Documentação"),
              children: [
                ListTile(
                  title: const Text("Protocolos Médicos"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_medical_protocols',
                      ),
                ),
                ListTile(
                  title: const Text("Documentos da Clínica"),
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/admin_clinic_documents',
                      ),
                ),
              ],
            ),
          ],

          // ---------------- Dentist ----------------
          if (userRole == "dentist") ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Meus Pacientes"),
              onTap: () => Navigator.pushNamed(context, '/dentist_patients'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Consultas"),
              onTap:
                  () => Navigator.pushNamed(context, '/dentist_appointments'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
          ],

          // ---------------- Nurse ----------------
          if (userRole == "nurse") ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text("Procedimentos"),
              onTap: () => Navigator.pushNamed(context, '/nurse_procedures'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Pacientes"),
              onTap: () => Navigator.pushNamed(context, '/nurse_patients'),
            ),
          ],

          // ---------------- Receptionist ----------------
          if (userRole == "receptionist") ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Pacientes"),
              onTap: () => Navigator.pushNamed(context, '/reception_patients'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Agendamentos"),
              onTap:
                  () => Navigator.pushNamed(context, '/reception_appointments'),
            ),
          ],
        ],
      ),
    );
  }
}
