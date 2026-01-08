import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/signup.dart';
import 'package:emergency_alert/app_theme.dart';
import 'package:emergency_alert/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // runApp(const MainApp());
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
          home: const SignupScreen(),
        );
      },
    );
  }
}
