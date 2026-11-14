import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:controle_clinica/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final String userRole;
  final Widget? floatingActionButton;

  const BasePage({
    super.key,
    required this.title,
    required this.body,
    required this.userRole,
    this.floatingActionButton,
  });

  /// Iniciais do usuário logado para o avatar (ou "?" se não houver nome).
  String _initials() {
    final user = AuthService().currentUser;
    final first = (user?["first_name"] ?? "").toString().trim();
    final last = (user?["last_name"] ?? "").toString().trim();

    final text =
        "${first.isEmpty ? "" : first[0]}${last.isEmpty ? "" : last[0]}";

    return text.isEmpty ? "?" : text.toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);

    await AuthService().clearToken();
    AuthService().currentUser = null;

    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            tooltip: "Opções do perfil",
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            onSelected: (value) {
              if (value == 'logout') _logout(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.sand,
                foregroundColor: AppColors.ink,
                child: Text(
                  _initials(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text("Perfil"),
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text("Configurações"),
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text("Sair"),
                      mouseCursor: SystemMouseCursors.click,
                      iconColor: AppColors.danger,
                      textColor: AppColors.danger,
                    ),
                  ),
                ],
          ),
        ],
      ),
      drawer: const Sidebar(userRole: "administrator"),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
