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
  int days = 50;
  int hours = 12;

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
    DateTime scheduleEndTime = actualDateTime.add(const Duration(days: 180));

    return SizedBox(
      width: 1000,
      height: 1200,
      child: Row(
        children: [
          // 🔹 Static left column with hours
          Column(
            spacing: 4,
            children: [
              const SizedBox(height: 18), // space for date header row
              ...List.generate(hours, (hourOffset) {
                return Container(
                  width: 60,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.grey.shade200,
                  ),
                  child: Text("${9 + hourOffset}:00"),
                );
              }),
            ],
          ),

          // 🔹 Scrollable right side with dates + grid
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                // pinch zoom on touch
                _updateWidth((details.scale - 1) * 10);
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    // mouse wheel scroll
                    _updateWidth(-event.scrollDelta.dy * 0.2);
                  }
                },
                child: InteractiveViewer(
                  panEnabled: true, // drag horizontally/vertically
                  panAxis: PanAxis.horizontal,
                  scaleEnabled: false, // pinch to zoom
                  minScale: 0.5,
                  maxScale: 2.5,
                  boundaryMargin: EdgeInsets.all(double.infinity),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          spacing: 4,
                          children: List.generate(days, (dayOffset) {
                            DateTime date = actualDateTime.add(
                              Duration(days: dayOffset),
                            );
                            return Container(
                              width: columnWidth,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                color: Colors.blue.shade50,
                              ),
                              child: Text(
                                "${date.day}/${date.month}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                        Expanded(
                          child: Row(
                            children: List.generate(days, (day) {
                              return Column(
                                children: List.generate(hours, (hour) {
                                  return Container(
                                    width: columnWidth,
                                    height: 20,
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text("${9 + hour}:00"),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
