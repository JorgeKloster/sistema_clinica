import 'package:controle_clinica/pages/admin/live_consultations_page.dart';
import 'package:controle_clinica/pages/admin/procedures_page.dart';
import 'package:controle_clinica/pages/admin/professionals_page.dart';
import 'package:controle_clinica/pages/admin/rooms_page.dart';
import 'package:controle_clinica/pages/common/appointment_page.dart';
import 'package:controle_clinica/pages/common/patient_page.dart';
import 'package:controle_clinica/pages/common/patients_page.dart';
import 'package:controle_clinica/pages/common/schedule_page.dart';
import 'package:controle_clinica/pages/common/splash_screen.dart';
import 'package:controle_clinica/pages/dentist/dentist_homepage.dart';
import 'package:controle_clinica/pages/login/login_page.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bucalle',
      theme: AppTheme.light(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(),
        '/dentist_home': (context) => DentistHomePage(),
        '/patient': (context) => const PatientPage(),
        '/schedule': (context) => SchedulePage(),
        '/appointment': (context) => const AppointmentPage(),
        '/patients': (context) => PatientsPage(),
        '/admin_professionals': (context) => ProfessionalsPage(),
        '/admin_procedures': (context) => ProceduresPage(),
        '/admin_resources': (context) => const RoomsPage(),
        '/admin_live_consultations': (context) => const LiveConsultationsPage(),
      },
    );
  }
}
