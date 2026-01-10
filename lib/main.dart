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

import 'firebase_options.dart';

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
  // final model =
  //       FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  // // Provide a prompt that contains text
  // final prompt = [Content.text('Write a story about a magic backpack.')];

  // To generate text output, call generateContent with the text input
  // final response = await model.generateContent(prompt);
  // print(response.text);
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
          home: _getInitialScreen(),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const EmergencyListScreen();
    }
    return const SignupScreen();
  }
}
