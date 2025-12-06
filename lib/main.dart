import 'package:emergency_alert/screens/emergency_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  await dotenv.load();
  final supabaseUrl = dotenv.get("SUPABASE_URL");
  final supabaseKey = dotenv.get("SUPABASE_KEY");
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        //we should do our color palette here https://docs.flutter.dev/cookbook/design/themes
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue) ,
      ),
      home: const Scaffold(
        body: SafeArea(
          //temporary , please change this to an actual home scree that includes the list
          child: Center(child: EmergencyList()),
        ),
      ),
    );
  }
}
