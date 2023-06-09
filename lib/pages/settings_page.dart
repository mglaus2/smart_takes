import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preferences_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String direction;

  @override
  void initState() {
    super.initState();
    getData().then((value) {
      setState(() {
        direction = value;
      });
    });
  }

  Future<void> toggleCameraDirection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var direction = prefs.getString(kCameraDirection);

    if (direction == "front") {
      direction = "back";
    } else {
      direction = "front";
    }

    await prefs.setString(kCameraDirection, direction);

    // Pass the updated camera direction as a parameter when navigating back
    Navigator.pop(context, direction);
  }

  Future<String> getData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var direction = prefs.getString(kCameraDirection);

    return direction!;
  }

  Future<void> handleIconTap() async {
    await toggleCameraDirection();
    // Refresh the UI or perform any other actions after the direction is toggled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: getData(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                String direction = snapshot.data ?? "front";
                return SettingsCard(
                  title: 'Camera Direction',
                  icon: Icons.camera,
                  onTap: handleIconTap,
                  subtitle: direction,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String subtitle;

  SettingsCard({
    required this.title,
    required this.icon,
    this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: onTap,
          child: Icon(icon),
        ),
      ),
    );
  }
}
