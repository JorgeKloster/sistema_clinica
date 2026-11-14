import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/api_exception.dart';
import 'package:controle_clinica/services/appointment_service.dart';
import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/services/patient_service.dart';
import 'package:controle_clinica/services/procedure_service.dart';
import 'package:controle_clinica/services/professional_service.dart';
import 'package:controle_clinica/services/room_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/form_dialog.dart';
import 'package:controle_clinica/widgets/week_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color _meColor = Color(0xFF00796B);
const List<Color> _palette = [
  Color(0xFF6A3FA0),
  Color(0xFFB04A12),
  Color(0xFF1565C0),
  Color(0xFFAD1457),
  Color(0xFF2E7D32),
  Color(0xFF5D4037),
];

const List<String> _monthsShort = [
  "jan", "fev", "mar", "abr", "mai", "jun",
  "jul", "ago", "set", "out", "nov", "dez",
];

DateTime _mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _weekStart = _mondayOf(DateTime.now());

  List<Appointment> _appointments = [];
  List<Map<String, dynamic>> _doctors = [];

  /// "me", "all" ou o id do profissional (como texto).
  String _doctorFilter = "all";

  bool _loading = true;
  Appointment? _selected;

  int _requestCounter = 0;
  bool _argsHandled = false;

  bool get _isAdmin => AuthService().role == 'admin';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final data = await ProfessionalService.getProfessionals();

      _doctors =
          data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((p) => p["role"] == "doctor")
              .toList();
    } catch (e) {
      _showMessage("Erro ao carregar profissionais: $e");
    }

    final myId = AuthService().userId;

    if (_doctors.any((d) => d["user_id"] == myId)) {
      _doctorFilter = "me";
    }

    await _load();

    if (!mounted || _argsHandled) return;
    _argsHandled = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map && args["patient_id"] is int) {
      await _showForm(patientId: args["patient_id"] as int);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  int? get _doctorIdFilter {
    switch (_doctorFilter) {
      case "all":
        return null;
      case "me":
        return AuthService().userId;
      default:
        return int.tryParse(_doctorFilter);
    }
  }

  Future<void> _load() async {
    final request = ++_requestCounter;

    setState(() => _loading = true);

    try {
      final list = await AppointmentService.getAppointments(
        from: _weekStart,
        to: _weekStart.add(const Duration(days: 7)),
        doctorId: _doctorIdFilter,
      );

      // Ignora respostas de uma semana/filtro que já foi trocado.
      if (!mounted || request != _requestCounter) return;

      setState(() {
        _appointments = list;
        _selected = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _requestCounter) return;

      setState(() => _loading = false);
      _showMessage(e.toString());
    }
  }

  void _goToWeek(DateTime day) {
    _weekStart = _mondayOf(day);
    _load();
  }

  Color _colorOf(Appointment a) {
    if (a.status == "completed") return const Color(0xFF7A7A7A);

    if (a.doctorId == AuthService().userId) return _meColor;

    final index = _doctors.indexWhere((d) => d["user_id"] == a.doctorId);

    return _palette[(index < 0 ? a.doctorId : index) % _palette.length];
  }

  String _rangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));

    final startText =
        _weekStart.month == end.month
            ? "${_weekStart.day}"
            : "${_weekStart.day} ${_monthsShort[_weekStart.month - 1]}";

    return "$startText – ${end.day} ${_monthsShort[end.month - 1]} ${end.year}";
  }

  String _weekPillLabel() {
    final thisWeek = _mondayOf(DateTime.now());
    final diff = _weekStart.difference(thisWeek).inDays ~/ 7;

    switch (diff) {
      case 0:
        return "Esta semana";
      case -1:
        return "Semana passada";
      case 1:
        return "Próxima semana";
      default:
        return "Semana de ${_weekStart.day}/${_weekStart.month}";
    }
  }

  String _doctorLabel() {
    if (_doctorFilter == "all") return "Todos os profissionais";

    final id = _doctorIdFilter;
    final doctor = _doctors.where((d) => d["user_id"] == id).toList();

    if (doctor.isEmpty) return "Meus agendamentos";

    final name = "${doctor.first["first_name"]} ${doctor.first["last_name"]}";

    return _doctorFilter == "me" ? "$name (eu)" : name;
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "Escolha um dia da semana",
    );

    if (picked != null) _goToWeek(picked);
  }

  // ---------------------------------------------------------------- filtros

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8CCC1)),
      ),
      child: child,
    );
  }

  Widget _weekPill() {
    return PopupMenuButton<String>(
      tooltip: "Escolher semana",
      onSelected: (value) {
        final thisWeek = _mondayOf(DateTime.now());

        switch (value) {
          case "prev":
            _goToWeek(thisWeek.subtract(const Duration(days: 7)));
            break;
          case "current":
            _goToWeek(thisWeek);
            break;
          case "next":
            _goToWeek(thisWeek.add(const Duration(days: 7)));
            break;
          case "pick":
            _pickWeek();
            break;
        }
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem(value: "prev", child: Text("Semana passada")),
            PopupMenuItem(value: "current", child: Text("Esta semana")),
            PopupMenuItem(value: "next", child: Text("Próxima semana")),
            PopupMenuDivider(),
            PopupMenuItem(value: "pick", child: Text("Escolher semana…")),
          ],
      child: _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              _weekPillLabel(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _doctorPill() {
    final myId = AuthService().userId;
    final iAmDoctor = _doctors.any((d) => d["user_id"] == myId);

    return PopupMenuButton<String>(
      tooltip: "Filtrar por profissional",
      onSelected: (value) {
        _doctorFilter = value;
        _load();
      },
      itemBuilder:
          (_) => [
            if (iAmDoctor)
              const PopupMenuItem(value: "me", child: Text("Meus agendamentos")),
            const PopupMenuItem(
              value: "all",
              child: Text("Todos os profissionais"),
            ),
            if (_doctors.isNotEmpty) const PopupMenuDivider(),
            for (final d in _doctors)
              if (d["user_id"] != myId)
                PopupMenuItem(
                  value: "${d["user_id"]}",
                  child: Text(
                    "${d["first_name"]} ${d["last_name"]}"
                    "${(d["specialty"] ?? "").toString().isEmpty ? "" : " · ${d["specialty"]}"}",
                  ),
                ),
          ],
      child: _pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 8),
            Text(
              _doctorLabel(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final count = _appointments.length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: "Semana anterior",
          onPressed:
              () => _goToWeek(_weekStart.subtract(const Duration(days: 7))),
          icon: const Icon(Icons.chevron_left),
        ),
        _weekPill(),
        IconButton(
          tooltip: "Próxima semana",
          onPressed: () => _goToWeek(_weekStart.add(const Duration(days: 7))),
          icon: const Icon(Icons.chevron_right),
        ),
        Text(
          _rangeLabel(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        _doctorPill(),
        Text(
          count == 1 ? "1 agendamento" : "$count agendamentos",
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  // ---------------------------------------------------------- detalhe/ações

  Future<void> _changeStatus(Appointment a, String status) async {
    try {
      await AppointmentService.updateStatus(a.id, status);
      _showMessage(
        status == "canceled"
            ? "Agendamento cancelado"
            : "Agendamento atualizado",
      );
      await _load();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _cancel(Appointment a) async {
    final ok = await showConfirmationDialog(
      context,
      title: "Cancelar agendamento",
      message:
          "Cancelar o agendamento de ${a.patientName} em "
          "${DateFormat('dd/MM HH:mm').format(a.start)}? "
          "O horário ficará livre.",
    );

    if (ok) await _changeStatus(a, "canceled");
  }

  Future<void> _delete(Appointment a) async {
    final ok = await showConfirmationDialog(
      context,
      title: "Excluir agendamento",
      message:
          "Excluir definitivamente o agendamento de ${a.patientName}? "
          "Para manter o histórico, prefira cancelar.",
    );

    if (!ok) return;

    try {
      await AppointmentService.deleteAppointment(a.id);
      _showMessage("Agendamento excluído");
      await _load();
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _openVisit(Appointment a) async {
    await Navigator.pushNamed(
      context,
      '/appointment',
      arguments: {'appointment_id': a.id},
    );

    // O atendimento pode ter mudado o status.
    if (mounted) await _load();
  }

  Widget _detailBar() {
    final a = _selected;

    if (a == null) return const SizedBox.shrink();

    final dateText = DateFormat("dd/MM/yyyy").format(a.start);
    final timeText =
        "${DateFormat('HH:mm').format(a.start)}–${DateFormat('HH:mm').format(a.end)}";

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "${a.procedureName} · $dateText, $timeText"
                  "${a.roomName.isEmpty ? "" : " · ${a.roomName}"}",
                ),
                Text(
                  "${a.doctorName}"
                  "${a.doctorSpecialty.isEmpty ? "" : " (${a.doctorSpecialty})"}"
                  " · ${a.statusLabel}",
                ),
                if (a.notes.isNotEmpty)
                  Text(
                    "Obs.: ${a.notes}",
                    style: const TextStyle(color: Colors.black54),
                  ),
              ],
            ),
            if (a.status == "scheduled")
              OutlinedButton(
                onPressed: () => _changeStatus(a, "confirmed"),
                child: const Text("Confirmar"),
              ),
            FilledButton.icon(
              onPressed: () => _openVisit(a),
              icon: Icon(
                a.status == "in_progress" || a.status == "completed"
                    ? Icons.assignment_outlined
                    : Icons.play_arrow,
              ),
              label: Text(
                a.status == "in_progress"
                    ? "Continuar atendimento"
                    : a.status == "completed"
                    ? "Ver atendimento"
                    : "Abrir atendimento",
              ),
            ),
            OutlinedButton(
              onPressed: () => _showForm(appointment: a),
              child: const Text("Editar"),
            ),
            OutlinedButton(
              onPressed: () => _cancel(a),
              child: const Text("Cancelar agendamento"),
            ),
            if (_isAdmin)
              TextButton(
                onPressed: () => _delete(a),
                child: const Text(
                  "Excluir",
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- formulário

  String _patientName(Map<String, dynamic> p) =>
      "${p["first_name"]} ${p["last_name"]}".trim();

  /// Abre o formulário de criação ([appointment] nulo) ou edição.
  /// [start] pré-preenche data/hora (toque em horário vazio) e [patientId]
  /// o paciente (vindo da lista de pacientes).
  Future<void> _showForm({
    Appointment? appointment,
    DateTime? start,
    int? patientId,
  }) async {
    List<Map<String, dynamic>> patients;
    List<Map<String, dynamic>> procedures;
    List<Map<String, dynamic>> rooms;

    try {
      final results = await Future.wait([
        PatientService.getPatients(),
        ProcedureService.getProcedures(),
        RoomService.getRooms(),
      ]);

      patients =
          results[0].map((e) => Map<String, dynamic>.from(e as Map)).toList();
      procedures =
          results[1].map((e) => Map<String, dynamic>.from(e as Map)).toList();
      rooms =
          results[2].map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _showMessage("Erro ao carregar dados do formulário: $e");
      return;
    }

    if (!mounted) return;

    if (patients.isEmpty) {
      _showMessage("Cadastre ao menos um paciente antes de agendar");
      return;
    }

    if (procedures.isEmpty) {
      _showMessage("Cadastre ao menos um procedimento antes de agendar");
      return;
    }

    if (rooms.isEmpty) {
      _showMessage("Cadastre ao menos uma sala em Salas e Recursos antes de agendar");
      return;
    }

    if (_doctors.isEmpty) {
      _showMessage("Cadastre ao menos um profissional de saúde antes de agendar");
      return;
    }

    final patientLabels = {
      for (final p in patients) "${p["patient_id"]}": _patientName(p),
    };
    final procedureLabels = {
      for (final p in procedures) "${p["procedure_id"]}": "${p["name"]}",
    };
    final roomLabels = {
      for (final r in rooms) "${r["room_id"]}": "${r["name"]} · ${r["room_type_name"]}",
    };
    // Sala sugerida por cada procedimento.
    final suggestedRoom = {
      for (final p in procedures) "${p["procedure_id"]}": "${p["room_id"]}",
    };
    final doctorLabels = {
      for (final d in _doctors)
        "${d["user_id"]}":
            "${d["first_name"]} ${d["last_name"]}"
            "${(d["specialty"] ?? "").toString().isEmpty ? "" : " · ${d["specialty"]}"}",
    };

    // Valor inicial só vale se existir entre as opções.
    String? initial(Object? value, Map<String, String> labels) {
      final key = value?.toString();

      return key != null && labels.containsKey(key) ? key : null;
    }

    final editing = appointment != null;

    final DateTime base =
        appointment?.start ??
        start ??
        (_weekStart.isBefore(DateTime.now()) &&
                DateTime.now().isBefore(
                  _weekStart.add(const Duration(days: 7)),
                )
            ? DateTime.now()
            : _weekStart);

    final DateTime startTime =
        appointment?.start ??
        start ??
        DateTime(base.year, base.month, base.day, 9);

    final DateTime endTime =
        appointment?.end ?? startTime.add(const Duration(hours: 1));

    String two(int n) => n.toString().padLeft(2, '0');
    String hm(DateTime d) => "${two(d.hour)}:${two(d.minute)}";

    // Duração sugerida de cada procedimento (minutos).
    final durations = {
      for (final p in procedures)
        "${p["procedure_id"]}": (p["duration_minutes"] as num?)?.toInt() ?? 60,
    };

    int? minutesOf(Object? text) {
      final parts = (text?.toString() ?? "").split(":");

      if (parts.length != 2) return null;

      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);

      return h == null || m == null ? null : h * 60 + m;
    }

    String hmOfMinutes(int total) {
      final clamped = total.clamp(0, 23 * 60 + 59);

      return "${two(clamped ~/ 60)}:${two(clamped % 60)}";
    }

    // Duração em uso: começa com a do agendamento (edição) e é atualizada ao
    // escolher o procedimento ou ao ajustar o fim manualmente. Mudar o início
    // mantém essa duração e move o fim.
    var span = appointment?.durationMinutes ?? 60;

    final myDoctorId = AuthService().userId;
    final defaultDoctor =
        appointment?.doctorId ??
        (_doctorIdFilter ??
            (_doctors.any((d) => d["user_id"] == myDoctorId)
                ? myDoctorId
                : null));

    final fields = <FormFieldConfig>[
      FormFieldConfig(
        name: "patient_id",
        label: "Paciente",
        type: FieldType.dropdown,
        required: true,
        options: patientLabels.keys.toList(),
        optionLabels: patientLabels,
        initialValue: initial(
          appointment?.patientId ?? patientId,
          patientLabels,
        ),
      ),
      FormFieldConfig(
        name: "doctor_id",
        label: "Profissional",
        type: FieldType.dropdown,
        required: true,
        options: doctorLabels.keys.toList(),
        optionLabels: doctorLabels,
        initialValue: initial(defaultDoctor, doctorLabels),
      ),
      FormFieldConfig(
        name: "procedure_id",
        label: "Procedimento",
        type: FieldType.dropdown,
        required: true,
        options: procedureLabels.keys.toList(),
        optionLabels: procedureLabels,
        initialValue: initial(appointment?.procedureId, procedureLabels),
        onChanged: (values, setText) {
          // O procedimento sugere a sala; o usuário pode trocar depois.
          final room = suggestedRoom["${values["procedure_id"]}"];

          if (room != null && roomLabels.containsKey(room)) {
            setText("room_id", room);
          }

          span = durations["${values["procedure_id"]}"] ?? span;

          final startMin = minutesOf(values["start_time"]);

          if (startMin != null) {
            setText("end_time", hmOfMinutes(startMin + span));
          }
        },
      ),
      FormFieldConfig(
        name: "room_id",
        label: "Sala",
        type: FieldType.dropdown,
        required: true,
        options: roomLabels.keys.toList(),
        optionLabels: roomLabels,
        initialValue: initial(
          (appointment?.roomId ?? 0) > 0
              ? appointment!.roomId
              : suggestedRoom["${appointment?.procedureId}"],
          roomLabels,
        ),
      ),
      FormFieldConfig(
        name: "date",
        label: "Data",
        type: FieldType.dateAny,
        required: true,
        initialValue: DateFormat('yyyy-MM-dd').format(startTime),
      ),
      FormFieldConfig(
        name: "start_time",
        label: "Início",
        type: FieldType.time,
        required: true,
        initialValue: hm(startTime),
        onChanged: (values, setText) {
          final startMin = minutesOf(values["start_time"]);

          if (startMin != null) {
            setText("end_time", hmOfMinutes(startMin + span));
          }
        },
      ),
      FormFieldConfig(
        name: "end_time",
        label: "Fim",
        type: FieldType.time,
        required: true,
        initialValue: hm(endTime),
        onChanged: (values, setText) {
          final startMin = minutesOf(values["start_time"]);
          final endMin = minutesOf(values["end_time"]);

          // Ajuste manual do fim vira a nova duração.
          if (startMin != null && endMin != null && endMin > startMin) {
            span = endMin - startMin;
          }
        },
      ),
      FormFieldConfig(
        name: "notes",
        label: "Observações",
        type: FieldType.multiline,
        initialValue: appointment?.notes,
      ),
      if (editing)
        FormFieldConfig(
          name: "status",
          label: "Status",
          type: FieldType.dropdown,
          required: true,
          options: appointmentStatusLabels.keys.toList(),
          optionLabels: appointmentStatusLabels,
          initialValue: appointment.status,
        ),
    ];

    await showDialog(
      context: context,
      builder:
          (_) => EntityFormDialog(
            title: editing ? "Editar agendamento" : "Novo agendamento",
            fields: fields,
            onSubmit: (values) async {
              final date = values["date"]?.toString() ?? "";
              final startText = values["start_time"]?.toString() ?? "";
              final endText = values["end_time"]?.toString() ?? "";

              final startsAt = DateTime.tryParse("${date}T$startText:00");
              final endsAt = DateTime.tryParse("${date}T$endText:00");

              if (startsAt == null || endsAt == null) {
                throw ApiException("Informe data e horários válidos");
              }

              if (!endsAt.isAfter(startsAt)) {
                throw ApiException("O horário final deve ser depois do inicial");
              }

              final body = <String, dynamic>{
                "patient_id": int.parse(values["patient_id"].toString()),
                "doctor_id": int.parse(values["doctor_id"].toString()),
                "procedure_id": int.parse(values["procedure_id"].toString()),
                "room_id": int.parse(values["room_id"].toString()),
                "starts_at": "${date}T$startText:00",
                "ends_at": "${date}T$endText:00",
                "notes": (values["notes"] ?? "").toString().trim(),
                if (editing) "status": values["status"],
              };

              if (editing) {
                await AppointmentService.updateAppointment(appointment.id, body);
              } else {
                await AppointmentService.createAppointment(body);
              }

              // Mostra a semana do agendamento salvo.
              _weekStart = _mondayOf(startsAt);

              await _load();

              _showMessage(
                editing ? "Agendamento atualizado" : "Agendamento criado",
              );
            },
          ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Agenda",
      userRole: "dentist",
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text("Novo agendamento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filters(),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    WeekGrid(
                      weekStart: _weekStart,
                      appointments: _appointments,
                      colorOf: _colorOf,
                      showDoctor: _doctorFilter == "all",
                      selectedId: _selected?.id,
                      onSelect: (a) => setState(() => _selected = a),
                      onSlotTap: (slot) => _showForm(start: slot),
                    ),
                    if (!_loading && _appointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          "Nenhum agendamento nesta semana. "
                          "Toque em um horário da grade para criar um.",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    _detailBar(),
                    const SizedBox(height: 80),
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
