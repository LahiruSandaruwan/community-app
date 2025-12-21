import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/env_config.dart';
import 'firebase_options.dart';
import 'services/crash_reporting_service.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/poll_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate environment configuration
  try {
    EnvConfig.validate();
    EnvConfig.printConfig();
  } catch (e) {
    // In production, this will prevent app from starting with invalid config
    debugPrint('Environment Configuration Error: $e');
    if (EnvConfig.isProduction) {
      rethrow;
    }
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');

    // Initialize crash reporting and analytics
    await CrashReportingService().initialize();
    AppLogger.info('Crash reporting and analytics initialized');
  } catch (e) {
    AppLogger.error(
      'Failed to initialize Firebase',
      error: e,
    );
    // Continue app startup even if Firebase fails
  }

  // PocketBase initialization is handled in PocketBaseService singleton
  // No separate initialization needed

  runApp(const EduConnectApp());
}

class EduConnectApp extends StatelessWidget {
  const EduConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => PollProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'EduConnect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
