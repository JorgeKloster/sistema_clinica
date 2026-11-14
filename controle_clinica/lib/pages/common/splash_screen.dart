import 'package:controle_clinica/services/auth_service.dart';
import 'package:controle_clinica/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.8, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authService = AuthService();

    // Mostra a marca por um instante mesmo que o token carregue rápido.
    await Future.wait([
      authService.loadToken(),
      Future<void>.delayed(const Duration(milliseconds: 1600)),
    ]);

    if (!mounted) return;

    if (authService.token != null) {
      Navigator.pushReplacementNamed(context, '/dentist_home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O fundo do logotipo é este mesmo marrom: a imagem se funde à tela.
      backgroundColor: AppColors.ink,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/bucalle.jpg', width: 260),
                const SizedBox(height: 28),
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.sand,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
