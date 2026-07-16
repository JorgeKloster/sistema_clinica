import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScheduleGrid extends StatefulWidget {
  const ScheduleGrid({super.key});

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

class _ScheduleGridState extends State<ScheduleGrid> {
  double columnWidth = 120;
  int days = 20;
  int hours = 24;

  void _updateWidth(double delta) {
    setState(() {
      columnWidth = (columnWidth + delta).clamp(60, 200);
      // 👆 smooth limits
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1000,
      height: 1200,
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
              child: Row(
                children: List.generate(days, (day) {
                  return Column(
                    children: List.generate(hours, (hour) {
                      return Container(
                        width: columnWidth,
                        height: 20,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Center(child: Text("${9 + hour}:00")),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
