import 'package:emergency_alert/screens/emergency_list.dart';
import 'package:flutter/material.dart';



const supabaseUrl = 'https://htmgggbripfonipfeuun.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
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
