import 'package:flutter/material.dart';

class EmergencyLocationScreen extends StatefulWidget {
  final void Function(String) onContinue;
  final void Function() onBack;
  const EmergencyLocationScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<EmergencyLocationScreen> createState() =>
      _EmergencyLocationScreenState();
}

class _EmergencyLocationScreenState extends State<EmergencyLocationScreen> {
  String location = '';
  bool locationConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepHeader(2),
              const SizedBox(height: 16),
              Text(
                'Where is the emergency located?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    location = '1234 Main Street, Downtown, City Center';
                    locationConfirmed = true;
                  });
                },
                icon: Icon(Icons.my_location),
                label: Text('Use Current Location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: location,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Enter address/location',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {
                  location = val;
                  locationConfirmed = false;
                }),
              ),
              const SizedBox(height: 8),
              if (locationConfirmed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location confirmed: $location',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Quick Location Options:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _quickLocationChip('City Hospital'),
                  _quickLocationChip('Central Park'),
                  _quickLocationChip('Shopping Mall'),
                  _quickLocationChip('Train Station'),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: location.isNotEmpty
                          ? () => widget.onContinue(location)
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

  Widget _quickLocationChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() {
        location = label;
        locationConfirmed = true;
      }),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
