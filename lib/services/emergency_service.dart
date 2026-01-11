import 'package:flutter/material.dart';

enum EmergencyType { ambulance, police, fire, car }

class EmergencyService {
  final EmergencyType type;
  final String name;
  final String number;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final String reassuranceText;
  final List<String> availableServices;

  const EmergencyService({
    required this.type,
    required this.name,
    required this.number,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.reassuranceText,
    required this.availableServices,
  });
}

// Static data for the 4 cards
const emergencyServices = <EmergencyService>[
  EmergencyService(
    type: EmergencyType.ambulance,
    name: 'Ambulance',
    number: '123',
    icon: Icons.local_hospital_rounded,
    background: Color(0xFFFFF1F0),
    iconColor: Color(0xFFE53935),
    reassuranceText:
        'An ambulance is coming to you now. Stay calm and keep the patient comfortable.',
    availableServices: [
      'Fast Transport',
      'Paramedic Care',
      'Life Support',
      'Medical Assistance',
    ],
  ),
  EmergencyService(
    type: EmergencyType.police,
    name: 'Police',
    number: '122',
    icon: Icons.shield_rounded,
    background: Color(0xFFE8F2FF),
    iconColor: Color(0xFF2962FF),
    reassuranceText:
        'Help is on the way. You are safe now. Take a deep breath.',
    availableServices: [
      'Emergency Response',
      'Crime Reporting',
      'Traffic Assistance',
      'Public Safety',
    ],
  ),
  EmergencyService(
    type: EmergencyType.fire,
    name: 'Fire Department',
    number: '111',
    icon: Icons.local_fire_department_rounded,
    background: Color(0xFFFFF4E5),
    iconColor: Color(0xFFF57C00),
    reassuranceText:
        'Firefighters are on their way. Stay safe and follow evacuation procedures.',
    availableServices: [
      'Fire Response',
      'Rescue Operations',
      'Hazmat',
      'Emergency Medical',
    ],
  ),
  EmergencyService(
    type: EmergencyType.car,
    name: 'Car',
    number: '126',
    icon: Icons.car_crash,
    background: Color(0xFFE9FFF1),
    iconColor: Color(0xFF00C853),
    reassuranceText:
        'A tow truck is on its way to you. Stay calm and wait for the truck to arrive.',
    availableServices: [
      'Tow Truck',
      'Roadside Assistance',
      'Car Lockout',
      'Flat Tire Change',
    ],
  ),
];
