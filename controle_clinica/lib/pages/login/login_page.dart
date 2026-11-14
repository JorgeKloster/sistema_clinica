import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    bool success = false;
    String? error;

    try {
      success = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!success) error = "E-mail ou senha inválidos.";
    } catch (_) {
      error = "Não foi possível conectar ao servidor. Tente novamente.";
    }

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/dentist_home');
      return;
    }

    setState(() {
      _isLoading = false;
      _error = error;
    });
  }

  // ----------------------------------------------------------------- blocos

  /// Painel da marca. O logotipo tem o mesmo marrom de fundo do painel.
  Widget _brandPanel({required bool compact}) {
    return Container(
      color: AppColors.ink,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 32,
        vertical: compact ? 20 : 48,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/bucalle.jpg', width: compact ? 130 : 300),
        ],
      ),
    );
  }

  Widget _form() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Bem-vindo de volta",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              "Entre com seu e-mail e senha para acessar o sistema.",
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: "E-mail",
                prefixIcon: Icon(Icons.mail_outline),
              ),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) {
                final text = (value ?? "").trim();

                if (text.isEmpty) return "Informe seu e-mail";
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return "E-mail inválido";
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: "Senha",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? "Mostrar senha" : "Ocultar senha",
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed:
                      () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              onFieldSubmitted: (_) => _login(),
              validator:
                  (value) => (value ?? "").isEmpty ? "Informe sua senha" : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _login,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "Entrar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;

          final formPanel = Container(
            color: AppColors.paper,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: _form()),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: _brandPanel(compact: false)),
                Expanded(flex: 4, child: formPanel),
              ],
            );
          }

          return Column(
            children: [_brandPanel(compact: true), Expanded(child: formPanel)],
          );
        },
      ),
    );
  }
}
