import 'package:emergency_alert/screens/profile/medical/medical_info_screen.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/signup.dart';
import 'screens/emergency/emergency_list_screen.dart';
import 'package:emergency_alert/app_theme.dart';
import 'package:emergency_alert/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/on-boarding.dart';

import 'firebase_options.dart';
import 'screens/drawer/home_shell_screen.dart';
import 'screens/drawer/app_drawer.dart';

import 'package:emergency_alert/screens/emergency/emergency_list_screen.dart';
import 'package:emergency_alert/screens/emergency/share_location_screen.dart';
import 'package:emergency_alert/screens/profile/profile_screen.dart';
import 'package:emergency_alert/screens/profile/contacts/contacts_screen.dart';
import 'package:emergency_alert/screens/drawer/settings/settings_screen.dart';
import 'package:emergency_alert/screens/drawer/history/emergency_history_screen.dart';

late final ThemeController themeController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load theme choice BEFORE runApp
  themeController = await ThemeController.load();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.get("SUPABASE_URL"),
    anonKey: dotenv.get("SUPABASE_KEY"),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
  }

  void _finishOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: _onboardingComplete
              ? _getInitialScreen()
              : OnboardingScreenWrapper(onFinish: _finishOnboarding),
          routes: {
            '/home': (context) => const HomeShellScreen(),
            '/history': (context) => const EmergencyHistoryScreen(),
            '/signup': (context) => const SignupScreen(),

            // Drawer destinations (Citizen)
            '/profile': (context) => const ProfileScreen(),
            '/medical': (context) => const MedicalInfoScreen(),
            '/contacts': (context) => const ContactsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }

  Widget _getInitialScreen() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Uses a Drawer wrapper so rubric navigation is visible.
      return const HomeShellScreen();
    }
    return const SignupScreen();
  }
}

class OnboardingScreenWrapper extends StatelessWidget {
  final VoidCallback onFinish;
  const OnboardingScreenWrapper({required this.onFinish, super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenWithCallback(onFinish: onFinish);
  }
}

class OnboardingScreenWithCallback extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreenWithCallback({required this.onFinish, super.key});

  @override
  State<OnboardingScreenWithCallback> createState() =>
      _OnboardingScreenWithCallbackState();
}

class _OnboardingScreenWithCallbackState
    extends State<OnboardingScreenWithCallback> {
  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(onFinish: widget.onFinish);
  }
}
