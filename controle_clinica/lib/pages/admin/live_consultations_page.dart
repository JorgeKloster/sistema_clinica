import 'dart:async';

import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Painel de atendimentos em andamento: um quadrado por sala mostrando o
/// atendimento em curso (paciente, procedimento, profissional, tempo) ou
/// que a sala está livre. Atualiza sozinho a cada 15 segundos.
class LiveConsultationsPage extends StatefulWidget {
  const LiveConsultationsPage({super.key});

  @override
  State<LiveConsultationsPage> createState() => _LiveConsultationsPageState();
}

class _Room {
  final int id;
  final String name;
  final String typeName;
  final Appointment? current;
  final Appointment? next;

  const _Room({
    required this.id,
    required this.name,
    required this.typeName,
    required this.current,
    required this.next,
  });
}

class _LiveConsultationsPageState extends State<LiveConsultationsPage> {
  static const Color _busy = Color(0xFFC77700);
  static const Color _free = Color(0xFF2E7D32);
  static const Color _waiting = Color(0xFF1565C0);

  List<_Room> _rooms = [];
  bool _loading = true;
  String? _error;

  /// Quando os dados foram carregados: o tempo de cada atendimento soma o
  /// que o servidor informou ao que passou desde então.
  DateTime _loadedAt = DateTime.now();

  Timer? _refresh;
  Timer? _tick;

  @override
  void initState() {
    super.initState();

    _load();

    _refresh = Timer.periodic(const Duration(seconds: 15), (_) => _load());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await RoomService.getLiveRooms();

      Appointment? parse(dynamic json) =>
          json == null
              ? null
              : Appointment.fromJson(Map<String, dynamic>.from(json as Map));

      final rooms =
          data.map((item) {
            final map = Map<String, dynamic>.from(item as Map);

            return _Room(
              id: map["room_id"],
              name: "${map["name"]}",
              typeName: "${map["room_type_name"]}",
              current: parse(map["current"]),
              next: parse(map["next"]),
            );
          }).toList();

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        _loadedAt = DateTime.now();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      // Mantém o que já estava na tela se uma atualização falhar.
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _clock(Duration d) =>
      "${_two(d.inHours)}:${_two(d.inMinutes % 60)}:${_two(d.inSeconds % 60)}";

  String _hm(DateTime d) => DateFormat('HH:mm').format(d);

  Future<void> _open(Appointment a) async {
    await Navigator.pushNamed(
      context,
      '/appointment',
      arguments: {'appointment_id': a.id},
    );

    if (mounted) await _load();
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _card(_Room room) {
    final current = room.current;
    final next = room.next;

    // Próximo já no horário (ou atrasado) e ainda não iniciado.
    final due = next != null && !next.start.isAfter(DateTime.now());

    final Color color =
        current != null
            ? _busy
            : due
            ? _waiting
            : _free;

    final String status =
        current != null
            ? "Ocupada"
            : due
            ? "Aguardando início"
            : "Livre";

    final shown = current ?? (due ? next : null);

    Widget body;

    if (current != null) {
      final elapsed =
          Duration(seconds: current.elapsedSeconds) +
          DateTime.now().difference(_loadedAt);

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          _line(Icons.medical_services_outlined, current.procedureName),
          _line(Icons.person_outline, current.doctorName),
          _line(
            Icons.schedule,
            "Previsto ${_hm(current.start)}–${_hm(current.end)}",
          ),
          const Spacer(),
          Text(
            _clock(elapsed),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    } else if (shown != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shown.patientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          _line(Icons.medical_services_outlined, shown.procedureName),
          _line(Icons.person_outline, shown.doctorName),
          _line(
            Icons.schedule,
            "Marcado para ${_hm(shown.start)}–${_hm(shown.end)}",
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Icon(
              Icons.check_circle_outline,
              size: 44,
              color: color.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
        ],
      );
    }

    // Rodapé: próximo agendamento do dia (quando não é o que já aparece).
    final footer =
        next != null && shown?.id != next.id
            ? "Próximo: ${_hm(next.start)} · ${next.patientName}"
            : null;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: InkWell(
        onTap: shown == null ? null : () => _open(shown),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          room.typeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: body),
              if (footer != null) ...[
                const Divider(height: 14),
                Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    final busy = _rooms.where((r) => r.current != null).length;
    final free = _rooms.length - busy;

    Widget chip(Color color, String text) {
      return Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(text),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip(_busy, busy == 1 ? "1 ocupada" : "$busy ocupadas"),
        chip(_free, free == 1 ? "1 livre" : "$free livres"),
        chip(_waiting, "Aguardando início"),
        if (_error != null)
          Text(
            "Falha ao atualizar: $_error",
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_rooms.isEmpty) {
      content = const Center(
        child: Text("Nenhuma sala cadastrada. Cadastre em Salas e Recursos."),
      );
    } else {
      content = GridView.builder(
        padding: const EdgeInsets.only(top: 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          mainAxisExtent: 230,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _rooms.length,
        itemBuilder: (context, index) => _card(_rooms[index]),
      );
    }

    return BasePage(
      title: "Atendimentos em andamento",
      userRole: "administrator",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_loading) _summary(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
