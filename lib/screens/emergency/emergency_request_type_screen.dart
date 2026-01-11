import 'package:flutter/material.dart';

class EmergencyRequestTypeScreen extends StatefulWidget {
  final void Function(String) onContinue;
  const EmergencyRequestTypeScreen({super.key, required this.onContinue});

  @override
  State<EmergencyRequestTypeScreen> createState() =>
      _EmergencyRequestTypeScreenState();
}

class _EmergencyRequestTypeScreenState
    extends State<EmergencyRequestTypeScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepHeader(1),
              const SizedBox(height: 16),
              Text(
                'What type of emergency are you reporting?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _emergencyTypeCard(
                'Cardiac Emergency',
                'Heart attack, chest pain, breathing difficulties',
                Icons.favorite,
                Colors.red.shade50,
                Colors.red.shade400,
              ),
              const SizedBox(height: 12),
              _emergencyTypeCard(
                'Traffic Accident',
                'Vehicle collision, road accident, injuries',
                Icons.directions_car,
                Colors.orange.shade50,
                Colors.orange.shade400,
              ),
              const SizedBox(height: 12),
              _emergencyTypeCard(
                'Medical Emergency',
                'General medical emergency, illness, injury',
                Icons.local_hospital,
                Colors.blue.shade50,
                Colors.blue.shade400,
              ),
              const SizedBox(height: 12),
              _emergencyTypeCard(
                'Other Emergency',
                'Fire, natural disaster, other urgent situations',
                Icons.flash_on,
                Colors.purple.shade50,
                Colors.purple.shade400,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: selectedType != null
                          ? () => widget.onContinue(selectedType!)
                          : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'In immediate danger?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.call),
                      label: const Text('Call 108 Now'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For life-threatening emergencies, call directly',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
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

  Widget _stepHeader(int step) {
    return Row(
      children: [
        Icon(Icons.phone, color: Colors.redAccent),
        const SizedBox(width: 8),
        Text(
          'Emergency Request',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Spacer(),
        ...List.generate(3, (i) => _stepCircle(i + 1, step)),
      ],
    );
  }

  Widget _stepCircle(int number, int current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: number == current
            ? Colors.redAccent
            : Colors.grey.shade300,
        child: Text(
          '$number',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _emergencyTypeCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color borderColor,
  ) {
    final selected = selectedType == title;
    return GestureDetector(
      onTap: () => setState(() => selectedType = title),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: selected ? borderColor : bgColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: borderColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
