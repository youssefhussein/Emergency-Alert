import 'package:flutter/material.dart';
// import '../../emergency_list_screen.dart';
import 'package:emergency_alert/screens/emergency/emergency_list_screen.dart';
import 'app_drawer.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(drawer: AppDrawer(), body: EmergencyListScreen());
  }
}
