import 'package:controle_clinica/pages/common/base_page.dart';
import 'package:flutter/material.dart';

class DentistHomePage extends StatelessWidget {
  const DentistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Dashboard",
      userRole: "dentist",
      body: Center(
        child: Text("Welcome, Dentist!", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
