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
  int hours = 16;
  int totalDays = 360;
  final ScrollController _scrollController = ScrollController();

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
              onHorizontalDragUpdate: (details) => _scrollController.jumpTo(
                _scrollController.offset - details.delta.dx,
              ),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    // mouse wheel scroll
                    _updateWidth(-event.scrollDelta.dy * 0.2);
                  }
                },
                child: Scrollbar(
                  controller: _scrollController, // 👈 add a controller
                  thumbVisibility: true,         // 👈 always show scrollbar
                  child:GridView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: hours, // rows = hours
                      childAspectRatio: columnWidth / 300, // width vs height
                    ),
                    itemCount: totalDays * hours,// pre-cache items for smoother scrolling
                    itemBuilder: (context, index) {
                      int dayOffset = index ~/ hours;
                      int hourOffset = index % hours;
                      DateTime date =
                          scheduleStartTime.add(Duration(days: dayOffset));

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
                            "${date.day}/${date.month}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
                        child: Center(
                          child: Text("${8 + hourOffset}:00"),
                        ),
                      );
                    },
                  ),
              ),
            ),
          ),
      );
  }
}
