import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';

// Import our own AuthProvider
import 'providers/auth_provider.dart' as app_auth;

// Firebase configuration
import 'firebase_options.dart';

// Providers
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/group_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/karma_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/in_app_notification_provider.dart';
import 'providers/privacy_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/ad_provider.dart';
import 'providers/currency_provider.dart';

// Services
import 'services/notification_service.dart';
import 'services/notification_manager.dart';
import 'services/background_notification_service.dart';
import 'services/performance_optimizer.dart';
import 'services/ad_service.dart';

// Constants
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/karma/karma_leaderboard_screen.dart';
import 'screens/admin/database_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialized successfully');

    // Firebase persistence is set to LOCAL by default in mobile apps
    debugPrint('Firebase persistence is set to LOCAL by default');

    // Check if there's a current user (non-blocking)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('Current user found on app start: ${currentUser.uid}');
      // Don't block app startup with token refresh
      currentUser.getIdToken(true).then((_) {
        debugPrint('Token refreshed successfully on app start');
      }).catchError((e) {
        debugPrint('Error refreshing token on app start: $e');
        // Sign out if token refresh fails
        FirebaseAuth.instance.signOut().then((_) {
          debugPrint('User signed out due to token refresh failure');
        });
      });
    } else {
      debugPrint('No current user found on app start');
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Initialize notification service and manager
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await NotificationManager.initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing notification service: $e');
  }

  // Initialize background notification service
  try {
    final backgroundNotificationService = BackgroundNotificationService();
    await backgroundNotificationService.initialize();
    debugPrint('Background notification service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing background notification service: $e');
  }

  // Initialize performance optimizer
  try {
    PerformanceOptimizer.optimizeApp();
    debugPrint('Performance optimizer initialized successfully');
  } catch (e) {
    debugPrint('Error initializing performance optimizer: $e');
  }

  // Initialize AdMob (non-blocking)
  AdService.initialize().then((_) {
    debugPrint('AdMob initialized successfully');
  }).catchError((e) {
    debugPrint('Error initializing AdMob: $e');
    // Continue app startup even if AdMob fails
  });

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _authCheckTimer;

  @override
  void initState() {
    super.initState();

    // Set up periodic auth check every 10 minutes
    _authCheckTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      authProvider.checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => KarmaProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => InAppNotificationProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: Consumer2<app_auth.AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, _) {
          // Create dynamic themes based on the selected primary color
          final lightTheme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.primaryColor,
              brightness: Brightness.light,
            ),
            textTheme: AppTheme.lightTheme.textTheme,
            appBarTheme: AppTheme.lightTheme.appBarTheme,
            cardTheme: AppTheme.lightTheme.cardTheme,
            elevatedButtonTheme: AppTheme.lightTheme.elevatedButtonTheme,
            inputDecorationTheme: AppTheme.lightTheme.inputDecorationTheme,
            bottomNavigationBarTheme: AppTheme.lightTheme.bottomNavigationBarTheme,
          );

          final darkTheme = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.primaryColor,
              brightness: Brightness.dark,
            ),
            textTheme: AppTheme.darkTheme.textTheme,
            appBarTheme: AppTheme.darkTheme.appBarTheme,
            cardTheme: AppTheme.darkTheme.cardTheme,
            elevatedButtonTheme: AppTheme.darkTheme.elevatedButtonTheme,
            inputDecorationTheme: AppTheme.darkTheme.inputDecorationTheme,
            bottomNavigationBarTheme: AppTheme.darkTheme.bottomNavigationBarTheme,
          );

          return MaterialApp(
            title: AppConstants.appName,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => authProvider.isLoading
                  ? const SplashScreen()
                  : authProvider.isAuthenticated
                      ? const HomeScreen()
                      : const AuthScreen(),
              '/karma_leaderboard': (context) => const KarmaLeaderboardScreen(),
              '/database_setup': (context) => const DatabaseSetupScreen(),
            },
          );
        },
      ),
    );
  }
}


