import 'package:emergency_alert/screens/emergency_list.dart';
import 'package:flutter/material.dart';

void main() {
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
