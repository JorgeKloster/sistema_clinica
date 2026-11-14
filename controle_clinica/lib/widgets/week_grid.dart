import 'package:controle_clinica/models/appointment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const List<String> _dayNames = ["SEG", "TER", "QUA", "QUI", "SEX", "SÁB", "DOM"];

/// Primeira e última hora exibidas. A última linha vai de 18:00 até 19:00.
const int _firstHour = 8;
const int _lastHour = 18;

const double _hourHeight = 56;
const double _gutter = 64;
const double _minDayWidth = 110;

const Color _line = Color(0xFFE2D8CF);
const Color _lineSoft = Color(0xFFEEE6DF);
const Color _muted = Color(0xFF6B5E54);
const Color _hourLabel = Color(0xFF7A6C60);
const Color _text = Color(0xFF2B2420);
const Color _dark = Color(0xFF41372E);
/// Fundo do dia atual e dos fins de semana (sábado e domingo).
const Color _todayBg = Color(0xFFF6F1EC);

bool _isWeekend(DateTime d) =>
    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _hm(DateTime d) => DateFormat('HH:mm').format(d);

/// Grade de uma semana: colunas de segunda a sábado (domingo opcional), uma
/// linha por hora. Domingo só aparece se houver agendamento nele. Agendamentos com horários
/// sobrepostos dividem a coluna lado a lado.
class WeekGrid extends StatelessWidget {
  /// Segunda-feira da semana exibida.
  final DateTime weekStart;
  final List<Appointment> appointments;
  final Color Function(Appointment) colorOf;

  /// Mostra o nome do profissional em cada bloco (útil na visão "todos").
  final bool showDoctor;

  final int? selectedId;
  final ValueChanged<Appointment> onSelect;

  /// Toque em um horário vazio (arredondado para 30 min).
  final ValueChanged<DateTime> onSlotTap;

  const WeekGrid({
    super.key,
    required this.weekStart,
    required this.appointments,
    required this.colorOf,
    required this.showDoctor,
    required this.selectedId,
    required this.onSelect,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayCount =
        appointments.any((a) => a.start.weekday == DateTime.sunday) ? 7 : 6;
    final today = DateTime.now();
    final days = List<DateTime>.generate(
      dayCount,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = _gutter + dayCount * _minDayWidth;
          final narrow = constraints.maxWidth < minWidth;

          final content = SizedBox(
            width: narrow ? minWidth : constraints.maxWidth,
            child: Column(
              children: [_buildHeader(days, today), _buildBody(days, today)],
            ),
          );

          if (!narrow) return content;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<DateTime> days, DateTime today) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          const SizedBox(width: _gutter),
          for (final day in days)
            Expanded(child: _buildDayHeader(day, _sameDay(day, today))),
        ],
      ),
    );
  }

  Widget _buildDayHeader(DateTime day, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isToday || _isWeekend(day) ? _todayBg : Colors.white,
        border: const Border(left: BorderSide(color: _lineSoft)),
      ),
      child: Column(
        children: [
          Text(
            _dayNames[day.weekday - 1],
            style: const TextStyle(
              fontSize: 12,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? _dark : Colors.transparent,
            ),
            child: Text(
              "${day.day}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isToday ? Colors.white : _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<DateTime> days, DateTime today) {
    final rows = _lastHour - _firstHour + 1;

    return SizedBox(
      height: rows * _hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _gutter,
            child: Column(
              children: [
                for (var h = _firstHour; h <= _lastHour; h++)
                  SizedBox(
                    height: _hourHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 8, 0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          "${h.toString().padLeft(2, '0')}:00",
                          style: const TextStyle(
                            fontSize: 11,
                            color: _hourLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final day in days)
            Expanded(
              child: _DayColumn(
                day: day,
                isToday: _sameDay(day, today),
                events:
                    appointments.where((a) => _sameDay(a.start, day)).toList(),
                colorOf: colorOf,
                showDoctor: showDoctor,
                selectedId: selectedId,
                onSelect: onSelect,
                onSlotTap: onSlotTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Agendamento já posicionado: [lane] é a faixa (0, 1, 2...) e [lanes] quantas
/// faixas o grupo de agendamentos sobrepostos usa.
class _Slot {
  final Appointment appointment;
  int lane = 0;
  int lanes = 1;

  _Slot(this.appointment);
}

List<_Slot> _layout(List<Appointment> list) {
  final sorted =
      list.map((a) => _Slot(a)).toList()..sort((a, b) {
        final byStart = a.appointment.start.compareTo(b.appointment.start);

        return byStart != 0
            ? byStart
            : a.appointment.end.compareTo(b.appointment.end);
      });

  final out = <_Slot>[];
  var cluster = <_Slot>[];
  var clusterEnd = DateTime.fromMillisecondsSinceEpoch(0);
  var laneEnds = <DateTime>[];

  void flush() {
    for (final slot in cluster) {
      slot.lanes = laneEnds.length;
    }
    out.addAll(cluster);
    cluster = <_Slot>[];
    laneEnds = <DateTime>[];
  }

  for (final slot in sorted) {
    final start = slot.appointment.start;
    final end = slot.appointment.end;

    // Começou depois do fim do grupo atual: fecha o grupo.
    if (cluster.isNotEmpty && !start.isBefore(clusterEnd)) flush();

    var lane = laneEnds.indexWhere((laneEnd) => !laneEnd.isAfter(start));

    if (lane == -1) {
      lane = laneEnds.length;
      laneEnds.add(end);
    } else {
      laneEnds[lane] = end;
    }

    slot.lane = lane;

    if (cluster.isEmpty || end.isAfter(clusterEnd)) clusterEnd = end;

    cluster.add(slot);
  }

  flush();

  return out;
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<Appointment> events;
  final Color Function(Appointment) colorOf;
  final bool showDoctor;
  final int? selectedId;
  final ValueChanged<Appointment> onSelect;
  final ValueChanged<DateTime> onSlotTap;

  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.events,
    required this.colorOf,
    required this.showDoctor,
    required this.selectedId,
    required this.onSelect,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _lastHour - _firstHour + 1;
    final slots = _layout(events);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final halfHours =
                (details.localPosition.dy / _hourHeight * 2).floor();

            onSlotTap(
              DateTime(
                day.year,
                day.month,
                day.day,
                _firstHour,
              ).add(Duration(minutes: halfHours * 30)),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: isToday || _isWeekend(day) ? _todayBg : Colors.white,
              border: const Border(left: BorderSide(color: _lineSoft)),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    for (var i = 0; i < rows; i++)
                      Container(
                        height: _hourHeight,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: _lineSoft)),
                        ),
                      ),
                  ],
                ),
                for (final slot in slots) _buildEvent(slot, width),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvent(_Slot slot, double columnWidth) {
    final a = slot.appointment;

    final startHour = a.start.hour + a.start.minute / 60;
    final endHour = a.end.hour + a.end.minute / 60;

    // Recorta o que estiver fora do intervalo exibido.
    final from = startHour < _firstHour ? _firstHour.toDouble() : startHour;
    final to = endHour > _lastHour + 1 ? (_lastHour + 1).toDouble() : endHour;

    if (to <= from) return const SizedBox.shrink();

    final laneWidth = columnWidth / slot.lanes;
    final height = (to - from) * _hourHeight - 2;

    return Positioned(
      left: slot.lane * laneWidth + 3,
      top: (from - _firstHour) * _hourHeight + 1,
      width: laneWidth - 6,
      height: height < 18 ? 18 : height,
      child: _EventBlock(
        appointment: a,
        color: colorOf(a),
        selected: selectedId == a.id,
        showDoctor: showDoctor,
        height: height,
        onTap: () => onSelect(a),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  final Appointment appointment;
  final Color color;
  final bool selected;
  final bool showDoctor;
  final double height;
  final VoidCallback onTap;

  const _EventBlock({
    required this.appointment,
    required this.color,
    required this.selected,
    required this.showDoctor,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final time = "${_hm(a.start)}–${_hm(a.end)}";

    final IconData? statusIcon =
        a.status == "completed"
            ? Icons.done_all
            : a.status == "confirmed"
            ? Icons.check_circle_outline
            : a.status == "in_progress"
            ? Icons.play_circle_outline
            : null;

    const white = TextStyle(color: Colors.white);

    // Mostra só as linhas que cabem: paciente, procedimento e, por último,
    // o profissional (visão "todos") ou o horário.
    final lines = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              a.patientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: white.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (statusIcon != null)
            Icon(statusIcon, size: 14, color: Colors.white),
        ],
      ),
      Text(
        a.procedureName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: white.copyWith(fontSize: 12),
      ),
      Text(
        [
          showDoctor ? a.doctorName : time,
          if (a.roomName.isNotEmpty) a.roomName,
        ].join(" · "),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: white.copyWith(fontSize: 11),
      ),
    ];

    // Altura de cada linha (fonte + folga) e padding vertical do bloco.
    // Só entram as linhas que cabem por inteiro; o resto é cortado.
    const lineHeights = [17.0, 16.0, 15.0];
    const verticalPadding = 6.0;

    var used = verticalPadding;
    var fit = 0;

    for (final h in lineHeights) {
      if (used + h > height + 2 && fit > 0) break;

      used += h;
      fit++;
    }

    return Semantics(
      button: true,
      selected: selected,
      label:
          "${a.patientName}, ${a.procedureName}, "
          "${_hm(a.start)} às ${_hm(a.end)}, ${a.doctorName}, "
          "${a.roomName}, ${a.statusLabel}",
      child: Material(
        color: color,
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side:
              selected
                  ? const BorderSide(color: _text, width: 2)
                  : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines.take(fit).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
