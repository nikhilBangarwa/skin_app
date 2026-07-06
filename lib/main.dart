import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'firebase_options.dart';
import 'core/theme/colors.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/localization_provider.dart';
import 'core/services/notification_service.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated firebase_options.dart configurations
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locProvider = Provider.of<LocalizationProvider>(context);

    // Sync static AppColors colors to match the theme before rebuilding the widget tree
    themeProvider.syncColors();

    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Skin Companion',
          debugShowCheckedModeBanner: false,
          
          // Themes Setup (Light & Dark Mode configs)
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localization Setup
          locale: locProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: const SplashScreen(),
        );
      },
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
          return Scaffold(
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
                return Scaffold(
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
