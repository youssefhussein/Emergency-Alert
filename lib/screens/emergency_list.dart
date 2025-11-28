import 'package:flutter/material.dart';

//static list of the emergencies , gonna make it so when u tap a card it takes you to a new screen (and passing its props)
class EmergencyList extends StatelessWidget {
  const EmergencyList({super.key});

  @override
  Widget build(BuildContext context) {
    return
        ListView(
          children: [

            Card(
              color: Colors.blueAccent,
              child: ListTile(
                leading: Icon(Icons.local_police_rounded),
                title: Text('Police'),
                subtitle: Text("Call your local police station"),
                trailing: Icon(Icons.arrow_forward_rounded),
              ),
            ),
            Card(
              color: Colors.red,
              child: ListTile(
                leading: Icon(Icons.local_hospital_rounded),
                title: Text('Hospital'),
                subtitle: Text("For medical emergencies"),
                trailing: Icon(Icons.arrow_forward_rounded),
              ),
            ),
            Card(
              color: Colors.red,
              child: ListTile(
                leading: Icon(Icons.local_fire_department_rounded),
                title: Text('Fire Department'),
                subtitle: Text("Put out the fire"),
                trailing: Icon(Icons.arrow_forward_rounded),
              ),
            ),
            Card(
              color: Colors.blueAccent,
              child: ListTile(
                leading: Icon(Icons.car_crash_rounded),
                title: Text('Tow truck'),
                subtitle: Text("Save your carrr"),
                trailing: Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ],
        );

  }
}
