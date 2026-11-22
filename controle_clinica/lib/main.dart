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
import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:controle_clinica/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final Map<String, WidgetBuilder> _routes = {
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
  };

  static const _publicRoutes = {'/splash', '/login'};

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final builder = _routes[settings.name];
    if (builder == null) return null;

    final needsLogin =
        !_publicRoutes.contains(settings.name) && !AuthService().hasValidToken;

    if (needsLogin) {
      return MaterialPageRoute(
        builder: (context) => LoginPage(),
        settings: const RouteSettings(name: '/login'),
      );
    }

    return MaterialPageRoute(builder: builder, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Bucalle',
      theme: AppTheme.light(),
      initialRoute: '/splash',
      onGenerateRoute: _onGenerateRoute,
    );
  }
}
