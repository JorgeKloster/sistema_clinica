import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/appointment_service.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Página inicial: saudação, atalhos conforme o perfil e a agenda de hoje.
class DentistHomePage extends StatefulWidget {
  const DentistHomePage({super.key});

  @override
  State<DentistHomePage> createState() => _DentistHomePageState();
}

class _Shortcut {
  final IconData icon;
  final String label;
  final String route;

  const _Shortcut(this.icon, this.label, this.route);
}

class _DentistHomePageState extends State<DentistHomePage> {
  List<Appointment> _today = [];
  bool _loading = true;
  String? _error;

  bool get _isDoctor => AuthService().role == "doctor";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);

    try {
      final list = await AppointmentService.getAppointments(
        from: day,
        to: day.add(const Duration(days: 1)),
        // Profissional vê a própria agenda; os demais perfis veem a clínica.
        doctorId: _isDoctor ? AuthService().userId : null,
      );

      if (!mounted) return;

      setState(() {
        _today = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final name = (AuthService().currentUser?["first_name"] ?? "").toString();

    final salutation =
        hour < 12
            ? "Bom dia"
            : hour < 18
            ? "Boa tarde"
            : "Boa noite";

    return name.isEmpty ? salutation : "$salutation, $name";
  }

  String _dateText() {
    const weekdays = [
      "segunda-feira",
      "terça-feira",
      "quarta-feira",
      "quinta-feira",
      "sexta-feira",
      "sábado",
      "domingo",
    ];
    const months = [
      "janeiro",
      "fevereiro",
      "março",
      "abril",
      "maio",
      "junho",
      "julho",
      "agosto",
      "setembro",
      "outubro",
      "novembro",
      "dezembro",
    ];

    final now = DateTime.now();

    return "${weekdays[now.weekday - 1]}, ${now.day} de ${months[now.month - 1]}";
  }

  List<_Shortcut> _shortcuts() {
    switch (AuthService().role) {
      case "admin":
        return const [
          _Shortcut(Icons.calendar_today_outlined, "Agenda", '/schedule'),
          _Shortcut(Icons.people_outline, "Pacientes", '/patients'),
          _Shortcut(
            Icons.access_time,
            "Atendimentos em andamento",
            '/admin_live_consultations',
          ),
          _Shortcut(
            Icons.badge_outlined,
            "Profissionais",
            '/admin_professionals',
          ),
          _Shortcut(
            Icons.medical_services_outlined,
            "Procedimentos",
            '/admin_procedures',
          ),
          _Shortcut(
            Icons.meeting_room_outlined,
            "Salas e Recursos",
            '/admin_resources',
          ),
        ];
      case "receptionist":
        return const [
          _Shortcut(Icons.calendar_today_outlined, "Agenda", '/schedule'),
          _Shortcut(Icons.people_outline, "Pacientes", '/patients'),
          _Shortcut(
            Icons.access_time,
            "Atendimentos em andamento",
            '/admin_live_consultations',
          ),
        ];
      default:
        return const [
          _Shortcut(Icons.calendar_today_outlined, "Agenda", '/schedule'),
          _Shortcut(Icons.people_outline, "Pacientes", '/patients'),
        ];
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "confirmed":
        return AppColors.info;
      case "in_progress":
        return AppColors.warning;
      case "completed":
        return AppColors.success;
      default:
        return AppColors.muted;
    }
  }

  Widget _shortcutCard(_Shortcut shortcut) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, shortcut.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.sand,
                foregroundColor: AppColors.ink,
                child: Icon(shortcut.icon),
              ),
              Text(
                shortcut.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentTile(Appointment a) {
    final color = _statusColor(a.status);
    final time = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/appointment',
            arguments: {'appointment_id': a.id},
          );

          if (mounted) await _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  time.format(a.start),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        a.procedureName,
                        if (a.roomName.isNotEmpty) a.roomName,
                        if (!_isDoctor) a.doctorName,
                      ].join(" · "),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  a.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todaySection() {
    Widget content;

    if (_loading) {
      content = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = Text(
        "Não foi possível carregar a agenda de hoje: $_error",
        style: const TextStyle(color: AppColors.danger),
      );
    } else if (_today.isEmpty) {
      content = const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.event_available_outlined, color: AppColors.muted),
              SizedBox(width: 12),
              Expanded(child: Text("Nenhum agendamento para hoje.")),
            ],
          ),
        ),
      );
    } else {
      content = Column(children: _today.map(_appointmentTile).toList());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isDoctor ? "Seus atendimentos de hoje" : "Agenda de hoje",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!_loading)
              Text(
                _today.length == 1 ? "1 agendamento" : "${_today.length} agendamentos",
                style: const TextStyle(color: AppColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortcuts = _shortcuts();

    return BasePage(
      title: "Início",
      userRole: "dentist",
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateText(),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 110,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: shortcuts.length,
                      itemBuilder:
                          (context, index) => _shortcutCard(shortcuts[index]),
                    ),
                    const SizedBox(height: 32),
                    _todaySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
