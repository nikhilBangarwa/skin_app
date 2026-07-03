import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated firebase_options.dart configurations
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        // Configures standard text theme to align with premium look
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
          titleLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
          bodyLarge: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontFamily: 'Quicksand', color: AppColors.textSecondary),
        ),
        // Premium card styling
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Dynamic Router checking Authentication State and Firestore Onboarding Status
class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // If Auth connection is still loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // User is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final String uid = authSnapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, firestoreSnapshot) {
              // While checking user's document in Firestore
              if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.background,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              // Document exists and onboarded is true
              if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
                final data = firestoreSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data['onboarded'] == true) {
                  return const HomeScreen();
                }
              }

              // Default route for authenticated user without completed onboarding
              return const OnboardingScreen();
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}
