import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../permissions/notification_permission_screen.dart';
import '../language/language_selection_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  List<_Particle> _particles = [];
  Widget _nextScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _mainController.forward();

    // Check routing path and enforce minimum 2.5s display duration
    Future.wait([
      _determineNextScreen(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]).then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => _nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  void _initParticles() {
    final random = Random();
    _particles = List.generate(24, (index) {
      return _Particle(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 0.7,
        size: 1.5 + random.nextDouble() * 2.5,
        opacity: 0.12 + random.nextDouble() * 0.38,
        angle: random.nextDouble() * 2 * pi,
      );
    });
  }

  Future<void> _determineNextScreen() async {
    final locProvider = Provider.of<LocalizationProvider>(context, listen: false);
    
    // 1. Check Notification Permission Screen Status
    final bool notificationShown = locProvider.notificationPermissionShown;
    if (!notificationShown) {
      _nextScreen = const NotificationPermissionScreen();
      return;
    }

    // 2. Check Language Selector Screen Status
    final bool languageSelected = locProvider.languageSelected;
    if (!languageSelected) {
      _nextScreen = const LanguageSelectionScreen();
      return;
    }

    // 3. Fallback to standard Auth Routing Check
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['onboarded'] == true) {
            _nextScreen = const HomeScreen();
            return;
          }
        }
        _nextScreen = const OnboardingScreen();
      } catch (e) {
        debugPrint('Splash Auth check error: $e');
        _nextScreen = const LoginScreen();
      }
    } else {
      _nextScreen = const LoginScreen();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background subtle gradients
          Positioned.fill(
            child: Container(
              color: AppColors.background,
            ),
          ),
          
          // Radial glow centered behind the logo
          Center(
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          // Particle Animation Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlesPainter(_particles, _particleController.value),
                );
              },
            ),
          ),

          // Center Logo and Tagline
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo Card with Rose Glow
                    Container(
                      height: 14.h,
                      width: 14.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 35,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.h),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    
                    // Brand Typography
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Skin',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    
                    // Tagline
                    Text(
                      context.l10n.splashTagline,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary.withValues(alpha: 0.65),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double xRatio;
  double yRatio;
  double speed;
  double size;
  double opacity;
  double angle;

  _Particle({
    required this.xRatio,
    required this.yRatio,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.angle,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlesPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      p.xRatio += cos(p.angle) * p.speed * 0.0006;
      p.yRatio += sin(p.angle) * p.speed * 0.0006;

      if (p.xRatio < 0) p.xRatio = 1.0;
      if (p.xRatio > 1.0) p.xRatio = 0.0;
      if (p.yRatio < 0) p.yRatio = 1.0;
      if (p.yRatio > 1.0) p.yRatio = 0.0;

      final dx = p.xRatio * size.width;
      final dy = p.yRatio * size.height;

      paint.color = AppColors.primary.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
