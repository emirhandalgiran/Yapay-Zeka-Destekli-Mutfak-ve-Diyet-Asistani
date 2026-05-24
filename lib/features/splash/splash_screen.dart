import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/auth_wrapper.dart';
import '../onboarding/onboarding_screen.dart';

/// Uygulama ilk açıldığında gösterilen animasyonlu splash ekranı.
/// Logo fade-in + scale, yazı slide-up animasyonları içerir.
class SplashScreen extends StatefulWidget {
  final bool showHome;

  const SplashScreen({super.key, required this.showHome});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            widget.showHome ? const AuthWrapper() : const OnboardingScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004D25),
              Color(0xFF006D37),
              Color(0xFF00873F),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'AuraCook',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Akıllı Mutfak Asistanınız',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 64),

            // Loading indicator
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            )
                .animate(delay: 1200.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
