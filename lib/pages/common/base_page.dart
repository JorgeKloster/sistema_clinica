import 'package:controle_clinica/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final String userRole;

  const BasePage({
    super.key,
    required this.title,
    required this.body,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(title)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            iconSize: 40,
            tooltip: "Opções do Perfil",
            elevation: 10,
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'profile') {
                // Navigate to profile page
              } else if (value == 'settings') {
                // Navigate to settings page
              } else if (value == 'logout') {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text("Perfil"),
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text("Configurações"),
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Sair"),
                      mouseCursor: SystemMouseCursors.click,
                      iconColor: Colors.redAccent,
                      textColor: Colors.redAccent,
                    ),
                  ),
                ],
          ),
        ],
      ),
      drawer: Sidebar(userRole: userRole),
      body: body,
    );
  }
}
