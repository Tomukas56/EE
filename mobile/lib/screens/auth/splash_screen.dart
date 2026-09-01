import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../legal/app_motto.dart';
import '../../widgets/app_emblem.dart';

class AppMottoBanner extends StatelessWidget {
  const AppMottoBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppMotto.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: compact ? 15 : 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0.2,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppEmblem(size: 140),
              SizedBox(height: 20),
              Text(
                'Energy Eniwhere',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: AppMottoBanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
