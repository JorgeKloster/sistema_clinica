import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:controle_clinica/widgets/schedule_grid.dart';
import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Agenda",
      userRole: "dentist",
      body: const ScheduleGrid(),
    );
  }
}
