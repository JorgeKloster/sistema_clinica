import 'package:controle_clinica/models/appointment.dart';
import 'package:controle_clinica/widgets/appointment_popup.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScheduleGrid extends StatefulWidget {
  const ScheduleGrid({super.key});

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  final DateTime actualDateTime = DateTime.now();
  double columnWidth = 120;
  int hoursPerDay = 16;
  int totalDays = 90;
  int startingHour = 8;
  final ScrollController _scrollController = ScrollController();

  String _weekdayName(int weekday) {
    const names = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];
    return names[weekday - 1];
  }

  // Example appointments
  final List<Appointment> appointments = [
    Appointment(
      id: 1,
      patientId: 1,
      patientName: "Juliana Souza",
      doctorId: 1,
      doctorName: "Dra. Joelyze",
      date: DateTime(2026, 10, 14),
      startTime: DateTime(2026, 10, 14, 8),
      endTime: DateTime(2026, 10, 14, 9),
      type: "Consulta",
      notes: "Verificar sensibilidade dentária",
    ),
    Appointment(
      id: 2,
      patientId: 4,
      patientName: "Lucas Souza",
      doctorId: 3,
      doctorName: "Dra. Marília",
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 8),
      endTime: DateTime(2026, 8, 23, 9),
      type: "Consulta",
      notes: "",
    ),
    Appointment(
      id: 3,
      patientId: 2,
      patientName: "Lucas Oliveira",
      doctorId: 2,
      doctorName: "Dr. Breno",
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 10),
      endTime: DateTime(2026, 8, 23, 11),
      type: "Implante",
      notes: "",
    ),
    Appointment(
      id: 4,
      patientId: 3,
      patientName: "Maria Silva",
      doctorId: 3,
      doctorName: "Dra. Marília",
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 14),
      endTime: DateTime(2026, 8, 23, 15, 59),
      type: "Consulta",
      notes: "",
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // pick the date you want to center on
      final DateTime targetDate = actualDateTime;

      // scheduleStartTime must match your grid start
      final DateTime scheduleStartTime = actualDateTime.subtract(
        const Duration(days: 45),
      );

      // how many days from grid start to target
      final int dayOffset = targetDate.difference(scheduleStartTime).inDays;

      // raw position in pixels
      final double targetPosition = dayOffset * columnWidth;

      // center it by subtracting half the viewport width
      final double viewportWidth = MediaQuery.of(context).size.width;
      final double centeredPosition = (targetPosition - viewportWidth / 2)
          .clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(centeredPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime scheduleStartTime = actualDateTime.subtract(
      const Duration(days: 45),
    );

    return SizedBox(
      width: totalDays * columnWidth,
      height: hoursPerDay * 40,
      child: GestureDetector(
        onHorizontalDragUpdate:
            (details) => _scrollController.jumpTo(
              _scrollController.offset - details.delta.dx,
            ),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _scrollController.jumpTo(
                _scrollController.offset + event.scrollDelta.dy * 0.4,
              );
            }
          },
          child: Scrollbar(
            controller: _scrollController, // 👈 add a controller
            thumbVisibility: true, // 👈 always show scrollbar
            child: CustomScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    // 👇 give the stack the same size as the grid
                    width: totalDays * columnWidth,
                    height: hoursPerDay * 40,
                    child: Stack(
                      children: [
                        // Background grid
                        GridView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: hoursPerDay,
                                childAspectRatio: 40 / columnWidth,
                              ),
                          itemCount: totalDays * hoursPerDay,
                          itemBuilder: (context, index) {
                            int dayOffset = index ~/ hoursPerDay;
                            int hourOffset = index % hoursPerDay;
                            final cellDateTime = DateTime(
                              scheduleStartTime.year,
                              scheduleStartTime.month,
                              scheduleStartTime.day + dayOffset,
                              startingHour -
                                  1 +
                                  hourOffset, // 👈 fixed base hour
                            );

                            if (hourOffset == 0) {
                              return Container(
                                width: columnWidth,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade300,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "${cellDateTime.day}/${cellDateTime.month} • ${_weekdayName(cellDateTime.weekday)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              width: columnWidth,
                              height: 40,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent, // 👈 no background
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                "${cellDateTime.hour}:00",
                                style: TextStyle(
                                  color: Colors.grey.shade400, // 👈 faint text
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          },
                        ),

                        // Foreground appointments
                        for (final appointment in appointments)
                          Positioned(
                            left:
                                (appointment.date
                                        .difference(scheduleStartTime)
                                        .inDays +
                                    1) *
                                columnWidth,
                            top:
                                (appointment.startTime.hour - 7) * 40 +
                                (appointment.startTime.minute / 60) * 40,
                            width: columnWidth,
                            height:
                                appointment.endTime
                                    .difference(appointment.startTime)
                                    .inMinutes /
                                60 *
                                40,
                            child: MouseRegion(
                              cursor:
                                  SystemMouseCursors
                                      .click, // 👈 changes pointer to hand
                              child: GestureDetector(
                                onTapUp: (details) {
                                  AppointmentPopup.show(
                                    context,
                                    details.globalPosition,
                                    appointment,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.teal.shade400,
                                        Colors.teal.shade600,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        appointment.patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        appointment.type,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
