import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/floating_gradients.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (credential.user != null) {
        await _checkOnboardingAndNavigate(credential.user!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar(_errorMessage ?? 'An error occurred during login.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        await _checkOnboardingAndNavigate(credential.user!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackBar(_errorMessage ?? 'Google Sign-in failed.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkOnboardingAndNavigate(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists && userDoc.data()?['onboarded'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 50),
                
                // Brand Header with Premium styling
                Center(
                  child: Column(
                    children: [
                      // Premium circular logo with glowing blur shadow
                      Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                          border: AppColors.glassBorder,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.blur_on,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Premium Typography
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Skin',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock your custom skin intelligence profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Form fields
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Address Input Label
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Email Textfield (Glassmorphism inspired card)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: AppColors.glassBorder,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            hintText: 'name@skincare.com',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
                            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegExp.hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Label
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: AppColors.glassBorder,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
                            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Gradient Premium Login Button with micro-interaction scale/glow
                      GestureDetector(
                        onTapDown: (_) => HapticFeedback.selectionClick(),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'or',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Button (Glassmorphism container with micro-shadow)
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.card.withValues(alpha: 0.5),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stylized Premium G representation
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Navigate to Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don’t have an account? ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Powered by AI Branding bottom text
                const Center(
                  child: Text(
                    'Powered by AI Skin Intelligence',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white24,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
