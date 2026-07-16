import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Schedule")),
      body: SizedBox(
        width: 1000, // 👈 force overflow (enough for many days)
        height: 1200,
        child: InteractiveViewer(
          panEnabled: true, // drag horizontally/vertically
          panAxis: PanAxis.horizontal,
          scaleEnabled: false, // pinch to zoom
          minScale: 0.5,
          maxScale: 2.5,
          boundaryMargin: EdgeInsets.all(double.infinity),
          child: OverflowBox(
            maxWidth: double.infinity,
            child: _buildScheduleGrid(),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleGrid() {
    // Example: rows = days, columns = hours
    return Row(
      children: List.generate(20, (day) {
        return Column(
          children: List.generate(12, (hour) {
            return Container(
              width: 120,
              height: 80,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Center(child: Text("${9 + hour}:00")),
            );
          }),
        );
      }),
    );
  }
}
