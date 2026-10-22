import 'package:controle_clinica/services/auth_service.dart';
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

  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authService = AuthService();
      final success = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/dentist_home');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Invalid email or password")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Clinic System Login",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter your email" : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? "Enter your password" : null,
                ),
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(onPressed: _login, child: Text("Login")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
