import 'package:controle_clinica/models/appointment.dart';
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
  int totalDays = 360;
  final ScrollController _scrollController = ScrollController();

  // Example appointments
  final List<Appointment> appointments = [
    Appointment(
      id: 1,
      patientId: 1,
      doctorId: 1,
      date: DateTime(2026, 8, 17),
      startTime: DateTime(2026, 8, 17, 8),
      endTime: DateTime(2026, 8, 17, 9),
      type: "Meeting",
      notes: "",
    ),
    Appointment(
      id: 2,
      patientId: 2,
      doctorId: 2,
      date: DateTime(2026, 8, 17),
      startTime: DateTime(2026, 8, 17, 10),
      endTime: DateTime(2026, 8, 17, 11),
      type: "Workshop",
      notes: "",
    ),
    Appointment(
      id: 3,
      patientId: 3,
      doctorId: 3,
      date: DateTime(2026, 8, 17),
      startTime: DateTime(2026, 8, 17, 14),
      endTime: DateTime(2026, 8, 17, 15),
      type: "Doctor",
      notes: "",
    ),
  ];

  void _updateWidth(double delta) {
    setState(() {
      columnWidth = (columnWidth + delta).clamp(60, 200);
      // 👆 smooth limits
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime scheduleStartTime = actualDateTime.subtract(
      const Duration(days: 180),
    );

    return SizedBox(
      width: 1000,
      height: 500,
      child: GestureDetector(
        onScaleUpdate: (details) {
          // pinch zoom on touch
          _updateWidth((details.scale - 1) * 10);
        },
        onHorizontalDragUpdate:
            (details) => _scrollController.jumpTo(
              _scrollController.offset - details.delta.dx,
            ),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              // mouse wheel scroll
              _updateWidth(event.scrollDelta.dy * 0.2);
            }
          },
          child: Scrollbar(
            controller: _scrollController, // 👈 add a controller
            thumbVisibility: true, // 👈 always show scrollbar
            child: Stack(
              children: [
                GridView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: hoursPerDay, // rows = hours
                    childAspectRatio: columnWidth / 300, // width vs height
                  ),
                  itemCount: totalDays * hoursPerDay,
                  itemBuilder: (context, index) {
                    int dayOffset = index ~/ hoursPerDay;
                    int hourOffset = index % hoursPerDay;
                    final cellDateTime = scheduleStartTime.add(
                      Duration(days: dayOffset, hours: hourOffset + 8),
                    );

                    if (hourOffset == 0) {
                      // Date header at top of each column
                      return Container(
                        width: columnWidth,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          color: Colors.blue.shade50,
                        ),
                        child: Text(
                          "${cellDateTime.day}/${cellDateTime.month}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    // Hour cells
                    return Container(
                      width: columnWidth,
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade100,
                      ),
                      child: Center(child: Text("${cellDateTime.hour}:00")),
                    );
                  },
                ),
                // Foreground appointments
                for (final appointment in appointments)
                  Positioned(
                    left:
                        appointment.date.difference(scheduleStartTime).inDays *
                        columnWidth,
                    top: (appointment.startTime.hour - 8) * 40,
                    width: columnWidth,
                    height:
                        appointment.endTime
                            .difference(appointment.startTime)
                            .inHours *
                        40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Center(child: Text(appointment.type)),
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
