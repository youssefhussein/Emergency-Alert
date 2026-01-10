import 'emergency_additional_info_screen.dart';
import '../../services/emergency_service.dart';

import 'package:flutter/material.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final EmergencyService service;
  const EmergencyDetailScreen({super.key, required this.service});

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  int _selectedType = -1;

  final List<_EmergencyType> _types = [
    _EmergencyType(
      icon: Icons.favorite_border,
      title: 'Cardiac Emergency',
      description: 'Heart attack, chest pain, breathing difficulties',
      color: Color(0xFFFFE5E5),
      borderColor: Color(0xFFFFB3B3),
      iconColor: Color(0xFFD32F2F),
      textColor: Color(0xFFD32F2F),
    ),
    _EmergencyType(
      icon: Icons.directions_car,
      title: 'Traffic Accident',
      description: 'Vehicle collision, road accident, injuries',
      color: Color(0xFFFFF6E0),
      borderColor: Color(0xFFFFD59E),
      iconColor: Color(0xFFF57C00),
      textColor: Color(0xFFF57C00),
    ),
    _EmergencyType(
      icon: Icons.local_hospital,
      title: 'Medical Emergency',
      description: 'General medical emergency, illness, injury',
      color: Color(0xFFE6F0FF),
      borderColor: Color(0xFFB3D1FF),
      iconColor: Color(0xFF1976D2),
      textColor: Color(0xFF1976D2),
    ),
    _EmergencyType(
      icon: Icons.warning_amber_outlined,
      title: 'Other Emergency',
      description: 'Fire, natural disaster, other urgent situations',
      color: Color(0xFFF3E6FF),
      borderColor: Color(0xFFD1B3FF),
      iconColor: Color(0xFF8E24AA),
      textColor: Color(0xFF8E24AA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.phone_in_talk, color: Colors.red[400]),
                            SizedBox(width: 8),
                            Text(
                              'Emergency Request',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildStepper(),
                        SizedBox(height: 16),
                        Text(
                          'What type of emergency are you reporting?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        ...List.generate(
                          _types.length,
                          (i) => _buildTypeCard(i),
                        ),
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _selectedType != -1
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EmergencyAdditionalInfoScreen(
                                              onBack: () =>
                                                  Navigator.pop(context),
                                              onSubmit: () {},
                                              type: _types[_selectedType].title,
                                              location:
                                                  'Unknown', // TODO: Replace with real location
                                            ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'In immediate danger?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          // Call 108
                        },
                        child: Text(
                          'Call 108 Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'For life-threatening emergencies, call directly',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _stepCircle(1, true),
        _stepLine(),
        _stepCircle(2, false),
        _stepLine(),
        _stepCircle(3, false),
      ],
    );
  }

  Widget _stepCircle(int step, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? Colors.red[600] : Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Colors.red[600]! : Colors.grey[400]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _stepLine() {
    return Container(width: 32, height: 2, color: Colors.grey[300]);
  }

  Widget _buildTypeCard(int index) {
    final type = _types[index];
    final selected = _selectedType == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: type.color,
          border: Border.all(
            color: selected ? type.borderColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(type.icon, color: type.iconColor, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: type.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      type.description,
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyType {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  _EmergencyType({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}
