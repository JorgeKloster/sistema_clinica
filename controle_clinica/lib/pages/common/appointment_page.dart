import 'dart:async';

import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/appointment_service.dart';
import 'package:controle_clinica/services/patient_service.dart';
import 'package:controle_clinica/services/procedure_service.dart';
import 'package:controle_clinica/widgets/confirmation_dialog.dart';
import 'package:controle_clinica/widgets/patient_health.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Página do atendimento. Recebe `{'appointment_id': int}` como argumento
/// de rota e mostra paciente, procedimento, cronômetro, anotações e o campo
/// de fotos.
class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  Appointment? _appointment;
  Map<String, dynamic>? _patient;
  Map<String, dynamic>? _procedure;
  List<Appointment> _history = [];

  final TextEditingController _notes = TextEditingController();
  Timer? _ticker;

  /// Quando o agendamento foi carregado: o cronômetro soma o tempo desde
  /// então ao que o servidor informou (elapsed_seconds).
  DateTime _loadedAt = DateTime.now();

  bool _loading = true;
  bool _busy = false;
  bool _notesDirty = false;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Os argumentos da rota só ficam disponíveis aqui, não no initState.
    if (_started) return;
    _started = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final id = args is Map ? args["appointment_id"] : null;

    if (id is int) {
      _load(id);
    } else {
      _loading = false;
      _error = "Agendamento não informado";
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notes.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appointment = await AppointmentService.getAppointment(id);

      final results = await Future.wait([
        PatientService.getPatients(),
        ProcedureService.getProcedures(),
      ]);

      Map<String, dynamic>? find(List<dynamic> list, String key, int value) {
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);

          if (map[key] == value) return map;
        }

        return null;
      }

      // O histórico é complementar: se falhar, o atendimento abre assim mesmo.
      var history = <Appointment>[];

      try {
        history = await AppointmentService.getPatientHistory(
          appointment.patientId,
          excludeAppointmentId: appointment.id,
        );
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _loadedAt = DateTime.now();
        _history = history;
        _appointment = appointment;
        _patient = find(results[0], "patient_id", appointment.patientId);
        _procedure = find(results[1], "procedure_id", appointment.procedureId);

        if (!_notesDirty) _notes.text = appointment.clinicalNotes;

        _loading = false;
      });

      _syncTicker();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Atualiza o cronômetro a cada segundo só enquanto estiver em atendimento.
  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;

    if (_appointment?.status == "in_progress") {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<bool> _saveNotes({bool quiet = false}) async {
    final appointment = _appointment;

    if (appointment == null) return true;

    try {
      await AppointmentService.updateClinicalNotes(
        appointment.id,
        _notes.text,
      );

      _notesDirty = false;

      if (!quiet) _showMessage("Anotações salvas");

      return true;
    } catch (e) {
      _showMessage(e.toString());

      return false;
    }
  }

  Future<void> _changeStatus(String status, String message) async {
    final appointment = _appointment;

    if (appointment == null || _busy) return;

    setState(() => _busy = true);

    try {
      // Garante que o que foi digitado não se perde ao mudar de etapa.
      if (_notesDirty && !await _saveNotes(quiet: true)) return;

      await AppointmentService.updateStatus(appointment.id, status);

      _showMessage(message);

      await _load(appointment.id);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    final ok = await showConfirmationDialog(
      context,
      title: "Finalizar atendimento",
      message: "Deseja concluir o atendimento de ${_appointment!.patientName}?",
    );

    if (ok) await _changeStatus("completed", "Atendimento concluído");
  }

  // ------------------------------------------------------------ utilitários

  String _two(int n) => n.toString().padLeft(2, '0');

  String _clock(Duration d) =>
      "${_two(d.inHours)}:${_two(d.inMinutes % 60)}:${_two(d.inSeconds % 60)}";

  int? _ageOf(String? birth) {
    if (birth == null || birth.length < 10) return null;

    final date = DateTime.tryParse(birth.substring(0, 10));

    if (date == null) return null;

    final now = DateTime.now();
    var age = now.year - date.year;

    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }

    return age;
  }

  Color _statusColor(String status) {
    switch (status) {
      case "confirmed":
        return const Color(0xFF1565C0);
      case "in_progress":
        return const Color(0xFFC77700);
      case "completed":
        return const Color(0xFF2E7D32);
      case "canceled":
        return const Color(0xFF9E2A2B);
      default:
        return const Color(0xFF6B5E54);
    }
  }

  // ----------------------------------------------------------------- blocos

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Appointment a) {
    final color = _statusColor(a.status);
    const weekdays = [
      "segunda",
      "terça",
      "quarta",
      "quinta",
      "sexta",
      "sábado",
      "domingo",
    ];

    final dayText =
        "${weekdays[a.start.weekday - 1]}, "
        "${DateFormat('dd/MM/yyyy').format(a.start)}";

    final time =
        "${DateFormat('HH:mm').format(a.start)}–${DateFormat('HH:mm').format(a.end)}";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.patientName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${a.procedureName} · $dayText · $time "
                  "(${a.durationMinutes} min)",
                ),
                Text(
                  "${a.doctorName}"
                  "${a.doctorSpecialty.isEmpty ? "" : " · ${a.doctorSpecialty}"}",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            Chip(
              label: Text(
                a.statusLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              backgroundColor: color.withValues(alpha: 0.12),
              side: BorderSide(color: color.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(Appointment a) {
    final started = a.startedAt;
    final finished = a.finishedAt;

    switch (a.status) {
      case "in_progress":
        // Tempo contado pelo servidor + o que passou desde que carregamos.
        // Assim o cronômetro continua certo ao sair e voltar à página, e não
        // depende do fuso do computador.
        final elapsed =
            Duration(seconds: a.elapsedSeconds) +
            DateTime.now().difference(_loadedAt);

        return _card(
          title: "Atendimento em andamento",
          icon: Icons.timer_outlined,
          child: Row(
            children: [
              Text(
                _clock(elapsed),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 16),
              if (started != null)
                Text(
                  "Iniciado às ${DateFormat('HH:mm').format(started)} "
                  "(previsto: ${a.durationMinutes} min)",
                  style: const TextStyle(color: Colors.black54),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _finish,
                icon: const Icon(Icons.check),
                label: const Text("Finalizar atendimento"),
              ),
            ],
          ),
        );

      case "completed":
        final real =
            started != null && finished != null
                ? finished.difference(started).inMinutes
                : null;

        return _card(
          title: "Atendimento concluído",
          icon: Icons.verified_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _info(
                "Início",
                started == null
                    ? ""
                    : DateFormat("dd/MM/yyyy HH:mm").format(started),
              ),
              _info(
                "Fim",
                finished == null
                    ? ""
                    : DateFormat("dd/MM/yyyy HH:mm").format(finished),
              ),
              _info(
                "Duração real",
                real == null ? "" : "$real min (previsto ${a.durationMinutes})",
              ),
            ],
          ),
        );

      case "canceled":
        return _card(
          title: "Agendamento cancelado",
          icon: Icons.event_busy_outlined,
          child: const Text("Este agendamento foi cancelado."),
        );

      default:
        return _card(
          title: "Pronto para atender",
          icon: Icons.play_circle_outline,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Ao iniciar, o horário real do atendimento começa a ser "
                  "registrado.",
                ),
              ),
              FilledButton.icon(
                onPressed:
                    _busy
                        ? null
                        : () => _changeStatus(
                          "in_progress",
                          "Atendimento iniciado",
                        ),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Iniciar atendimento"),
              ),
            ],
          ),
        );
    }
  }

  Widget _patientCard() {
    final p = _patient;

    if (p == null) {
      return _card(
        title: "Paciente",
        icon: Icons.person_outline,
        child: Text(_appointment!.patientName),
      );
    }

    final age = _ageOf(p["birth_date"]?.toString());
    final birth = (p["birth_date"] ?? "").toString();

    String birthText = "";

    if (birth.length >= 10) {
      final date = DateTime.tryParse(birth.substring(0, 10));

      if (date != null) {
        birthText =
            "${DateFormat('dd/MM/yyyy').format(date)}"
            "${age == null ? "" : " ($age anos)"}";
      }
    }

    return _card(
      title: "Paciente",
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info("Nome", "${p["first_name"]} ${p["last_name"]}"),
          _info("Nascimento", birthText),
          _info("Sexo", "${p["gender"] ?? ""}"),
          _info("CPF", "${p["cpf"] ?? ""}"),
          _info("Telefone", "${p["phone"] ?? ""}"),
          _info("E-mail", "${p["email"] ?? ""}"),
        ],
      ),
    );
  }

  Future<void> _editHealth() async {
    final patient = _patient;
    final appointment = _appointment;

    if (patient == null || appointment == null) return;

    if (await showPatientHealthDialog(context, patient)) {
      _showMessage("Informações de saúde atualizadas");

      await _load(appointment.id);
    }
  }

  /// Alergias, condições e medicamentos em destaque: é o que o profissional
  /// precisa ver antes de começar, e onde ele mantém essas informações.
  Widget _healthAlert() {
    final p = _patient;

    if (p == null) return const SizedBox.shrink();

    final hasAllergies = healthItems(p["allergies"]).isNotEmpty;
    final hasInfo =
        hasAllergies ||
        healthItems(p["medical_conditions"]).isNotEmpty ||
        healthItems(p["medications"]).isNotEmpty;

    final color =
        hasAllergies
            ? const Color(0xFF9E2A2B)
            : hasInfo
            ? const Color(0xFFC77700)
            : const Color(0xFF6B5E54);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasInfo ? Icons.warning_amber_rounded : Icons.health_and_safety,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                "Saúde do paciente",
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PatientHealthView(patient: p, onEdit: _editHealth),
        ],
      ),
    );
  }

  Widget _historyCard() {
    final format = DateFormat("dd/MM/yyyy HH:mm");

    return _card(
      title: "Histórico do paciente (${_history.length})",
      icon: Icons.history,
      child:
          _history.isEmpty
              ? const Text("Nenhum atendimento anterior registrado.")
              : Column(
                children:
                    _history.map((h) {
                      final color = _statusColor(h.status);
                      final details = [
                        if (h.clinicalNotes.isNotEmpty)
                          "Anotações: ${h.clinicalNotes}",
                        if (h.notes.isNotEmpty) "Agendamento: ${h.notes}",
                      ];

                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 10),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        title: Text(
                          "${format.format(h.start)} · ${h.procedureName}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "${h.doctorName} · ${h.statusLabel}",
                          style: TextStyle(color: color),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              details.isEmpty
                                  ? "Sem anotações neste atendimento."
                                  : details.join("\n\n"),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
    );
  }

  Widget _procedureCard(Appointment a) {
    final description = (_procedure?["description"] ?? "").toString();

    return _card(
      title: "Procedimento",
      icon: Icons.medical_services_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info("Procedimento", a.procedureName),
          _info("Sala", a.roomName),
          if (description.isNotEmpty) _info("Descrição", description),
          _info(
            "Duração sugerida",
            _procedure == null ? "" : "${_procedure!["duration_minutes"]} min",
          ),
          _info("Observações", a.notes),
        ],
      ),
    );
  }

  Widget _notesCard(Appointment a) {
    final locked = a.status == "canceled";

    return _card(
      title: "Anotações do atendimento",
      icon: Icons.notes_outlined,
      trailing: TextButton.icon(
        onPressed: locked || !_notesDirty ? null : () => _saveNotes(),
        icon: const Icon(Icons.save_outlined),
        label: const Text("Salvar"),
      ),
      child: TextField(
        controller: _notes,
        enabled: !locked,
        minLines: 6,
        maxLines: 14,
        onChanged: (_) {
          if (!_notesDirty) setState(() => _notesDirty = true);
        },
        decoration: InputDecoration(
          hintText: "Queixa, procedimentos realizados, orientações...",
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Só o campo: o armazenamento das imagens (MongoDB) ainda não existe.
  /// Quando for integrar, troque o corpo de [_addPhotos] e a lista [_photos].
  Widget _photosCard() {
    return _card(
      title: "Fotos do atendimento",
      icon: Icons.photo_camera_outlined,
      trailing: OutlinedButton.icon(
        onPressed: _addPhotos,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text("Adicionar fotos"),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              "Nenhuma foto neste atendimento",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _addPhotos() {
    // TODO: selecionar imagens e enviá-las ao serviço de armazenamento
    // (MongoDB), guardando só o id/URL de cada foto no atendimento.
    _showMessage("O envio de fotos será integrado ao MongoDB em breve");
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final a = _appointment;

    Widget body;

    if (_loading && a == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (a == null) {
      body = Center(child: Text(_error ?? "Agendamento não encontrado"));
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_patientCard(), _procedureCard(a), _historyCard()],
          );

          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_controls(a), _notesCard(a), _photosCard()],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(a),
                _healthAlert(),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: left),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: right),
                    ],
                  )
                else ...[
                  right,
                  left,
                ],
              ],
            ),
          );
        },
      );
    }

    return BasePage(title: "Atendimento", userRole: "dentist", body: body);
  }
}
