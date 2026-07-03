import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
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

    // Run auth check and display splash screen for at least 2.5 seconds
    Future.wait([
      _checkAuth(),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F1115),
                    Color(0xFF151922),
                    Color(0xFF1A1D24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Radial glow centered behind the logo
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF4A7A1).withValues(alpha: 0.08),
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
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF4A7A1).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF4A7A1).withValues(alpha: 0.28),
                            blurRadius: 35,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(55),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Brand Typography
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Skin',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF4A7A1),
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Tagline
                    Text(
                      'AI POWERED SKIN ANALYSIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.45),
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
      // Move particle slowly in the direction of its angle
      p.xRatio += cos(p.angle) * p.speed * 0.0006;
      p.yRatio += sin(p.angle) * p.speed * 0.0006;

      // Wrap around bounds
      if (p.xRatio < 0) p.xRatio = 1.0;
      if (p.xRatio > 1.0) p.xRatio = 0.0;
      if (p.yRatio < 0) p.yRatio = 1.0;
      if (p.yRatio > 1.0) p.yRatio = 0.0;

      final dx = p.xRatio * size.width;
      final dy = p.yRatio * size.height;

      paint.color = const Color(0xFFF4A7A1).withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
