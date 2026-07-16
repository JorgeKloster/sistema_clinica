import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String userRole;

  const Sidebar({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(child: Text("Clinic System")),
          if (userRole == "dentist") ...[
            ListTile(
              title: Text("My Patients"),
              onTap: () => Navigator.pushNamed(context, '/dentist_patients'),
            ),
            ListTile(
              title: Text("Appointments"),
              onTap:
                  () => Navigator.pushNamed(context, '/dentist_appointments'),
            ),
            ListTile(
              title: Text("Agenda"),
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
          ],
        ],
      ),
    );
  }
}
