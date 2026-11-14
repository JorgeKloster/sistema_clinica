import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String userRole;

  const Sidebar({super.key, required this.userRole});

  bool _isCurrent(BuildContext context, String route) =>
      ModalRoute.of(context)?.settings.name == route;

  /// Fecha o menu e vai para a tela (sem empilhar a que já está aberta).
  void _go(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    final current = ModalRoute.of(context)?.settings.name;

    navigator.pop(); // fecha o drawer

    if (current != route) navigator.pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              // O fundo do logotipo é o mesmo marrom do cabeçalho.
              child: Image.asset('assets/images/bucalle.jpg', height: 120),
            ),
          ),
          const SizedBox(height: 8),

          // ---------------- Administrator ----------------
          if (userRole == "administrator") ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Atendimentos em andamento"),
              selected: _isCurrent(context, '/admin_live_consultations'),
              onTap: () => _go(context, '/admin_live_consultations'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              selected: _isCurrent(context, '/schedule'),
              onTap: () => _go(context, '/schedule'),
            ),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text("Gerenciamento"),
              children: [
                ListTile(
                  title: const Text("Pacientes"),
                  selected: _isCurrent(context, '/patients'),
              onTap: () => _go(context, '/patients'),
                ),
                ListTile(
                  title: const Text("Profissionais"),
                  selected: _isCurrent(context, '/admin_professionals'),
              onTap: () => _go(context, '/admin_professionals'),
                ),
                ListTile(
                  title: const Text("Procedimentos"),
                  selected: _isCurrent(context, '/admin_procedures'),
              onTap: () => _go(context, '/admin_procedures'),
                ),
                ListTile(
                  title: const Text("Salas e Recursos"),
                  selected: _isCurrent(context, '/admin_resources'),
              onTap: () => _go(context, '/admin_resources'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.analytics),
              title: const Text("Relatórios"),
              children: [
                ListTile(
                  title: const Text("Financeiro"),
                  selected: _isCurrent(context, '/admin_reports_financial'),
              onTap: () => _go(context, '/admin_reports_financial'),
                ),
                ListTile(
                  title: const Text("Atendimentos"),
                  selected: _isCurrent(context, '/admin_reports_appointments'),
              onTap: () => _go(context, '/admin_reports_appointments'),
                ),
                ListTile(
                  title: const Text("Estatísticas de Pacientes"),
                  selected: _isCurrent(context, '/admin_reports_patients'),
              onTap: () => _go(context, '/admin_reports_patients'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Administração"),
              children: [
                ListTile(
                  title: const Text("Controle de Acesso"),
                  selected: _isCurrent(context, '/admin_access_control'),
              onTap: () => _go(context, '/admin_access_control'),
                ),
                ListTile(
                  title: const Text("Configurações da Clínica"),
                  selected: _isCurrent(context, '/admin_settings'),
              onTap: () => _go(context, '/admin_settings'),
                ),
                ListTile(
                  title: const Text("Integrações"),
                  selected: _isCurrent(context, '/admin_integrations'),
              onTap: () => _go(context, '/admin_integrations'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.message),
              title: const Text("Comunicação"),
              children: [
                ListTile(
                  title: const Text("Mensagens Internas"),
                  selected: _isCurrent(context, '/admin_internal_messages'),
              onTap: () => _go(context, '/admin_internal_messages'),
                ),
                ListTile(
                  title: const Text("Notificações aos Pacientes"),
                  selected: _isCurrent(context, '/admin_patient_notifications'),
              onTap: () => _go(context, '/admin_patient_notifications'),
                ),
              ],
            ),
            ExpansionTile(
              leading: const Icon(Icons.description),
              title: const Text("Suporte & Documentação"),
              children: [
                ListTile(
                  title: const Text("Protocolos Médicos"),
                  selected: _isCurrent(context, '/admin_medical_protocols'),
              onTap: () => _go(context, '/admin_medical_protocols'),
                ),
                ListTile(
                  title: const Text("Documentos da Clínica"),
                  selected: _isCurrent(context, '/admin_clinic_documents'),
              onTap: () => _go(context, '/admin_clinic_documents'),
                ),
              ],
            ),
          ],

          // ---------------- Dentist ----------------
          if (userRole == "dentist") ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Meus Pacientes"),
              selected: _isCurrent(context, '/dentist_patients'),
              onTap: () => _go(context, '/dentist_patients'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Consultas"),
              selected: _isCurrent(context, '/dentist_appointments'),
              onTap: () => _go(context, '/dentist_appointments'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              selected: _isCurrent(context, '/schedule'),
              onTap: () => _go(context, '/schedule'),
            ),
          ],

          // ---------------- Nurse ----------------
          if (userRole == "nurse") ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              selected: _isCurrent(context, '/schedule'),
              onTap: () => _go(context, '/schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text("Procedimentos"),
              selected: _isCurrent(context, '/nurse_procedures'),
              onTap: () => _go(context, '/nurse_procedures'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Pacientes"),
              selected: _isCurrent(context, '/nurse_patients'),
              onTap: () => _go(context, '/nurse_patients'),
            ),
          ],

          // ---------------- Receptionist ----------------
          if (userRole == "receptionist") ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Atendimentos em andamento"),
              selected: _isCurrent(context, '/admin_live_consultations'),
              onTap: () => _go(context, '/admin_live_consultations'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Agenda"),
              selected: _isCurrent(context, '/schedule'),
              onTap: () => _go(context, '/schedule'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Pacientes"),
              selected: _isCurrent(context, '/reception_patients'),
              onTap: () => _go(context, '/reception_patients'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Agendamentos"),
              selected: _isCurrent(context, '/reception_appointments'),
              onTap: () => _go(context, '/reception_appointments'),
            ),
          ],
        ],
      ),
    );
  }
}
