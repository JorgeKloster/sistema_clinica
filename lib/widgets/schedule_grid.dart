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
  double columnWidth = 100;
  int hoursPerDay = 16;
  int totalDays = 90;
  final ScrollController _scrollController = ScrollController();

  // Example appointments
  final List<Appointment> appointments = [
    Appointment(
      id: 1,
      patientId: 1,
      doctorId: 1,
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 8),
      endTime: DateTime(2026, 8, 23, 9),
      type: "Meeting",
      notes: "",
    ),
    Appointment(
      id: 2,
      patientId: 2,
      doctorId: 2,
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 10),
      endTime: DateTime(2026, 8, 23, 11),
      type: "Workshop",
      notes: "",
    ),
    Appointment(
      id: 3,
      patientId: 3,
      doctorId: 3,
      date: DateTime(2026, 8, 23),
      startTime: DateTime(2026, 8, 23, 14),
      endTime: DateTime(2026, 8, 23, 15, 59),
      type: "Doctor",
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
                            final cellDateTime = scheduleStartTime.add(
                              Duration(days: dayOffset, hours: hourOffset + 5),
                            );

                            if (hourOffset == 0) {
                              return Container(
                                width: columnWidth,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  color: Colors.blue.shade50,
                                ),
                                child: Text(
                                  "${cellDateTime.day}/${cellDateTime.month}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            return Container(
                              width: columnWidth,
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                color: Colors.grey.shade100,
                              ),
                              child: Center(
                                child: Text("${cellDateTime.hour}:00"),
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  "${appointment.type}\n${appointment.startTime.hour}:${appointment.startTime.minute.toString().padLeft(2, '0')} - ${appointment.endTime.hour}:${appointment.endTime.minute.toString().padLeft(2, '0')}",
                                  textAlign: TextAlign.center,
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
