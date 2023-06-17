import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_takes_app/camera_page.dart';

import '../constants/shared_preferences_constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String direction;
  late String zoomPreference;

  @override
  void initState() {
    super.initState();
    getCameraDirection().then((value) {
      setState(() {
        direction = value;
      });
    });
    getZoomPreference().then((value) {
      setState(() {
        zoomPreference = value;
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
    //Navigator.pop(context, direction);
  }

  Future<void> toggleZoomPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var zoomPreference = prefs.getString(kZoomPreference);

    if (zoomPreference == "reset") {
      zoomPreference = "keep";
    } else {
      zoomPreference = "reset";
    }

    await prefs.setString(kZoomPreference, zoomPreference);

    // Pass the updated camera direction as a parameter when navigating back
    //Navigator.pop(context, direction);
  }

  Future<void> _returnToCameraPage() async {
    final route = MaterialPageRoute(fullscreenDialog: true,
      builder: (_) {
        return CameraPage(cameraDirection: direction, zoomPreference: zoomPreference);
      },
    );
    await Navigator.pushReplacement(context, route).then((value) {});
  }

  Future<String> getCameraDirection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var direction = prefs.getString(kCameraDirection);

    return direction!;
  }

  Future<String> getZoomPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var zoomPreference = prefs.getString(kZoomPreference);

    return zoomPreference!;
  }

  Future<void> handleCameraDirectionIconTap() async {
    await toggleCameraDirection();
    getCameraDirection().then((value) {
      setState(() {
        direction = value;
      });
    });
    // Refresh the UI or perform any other actions after the direction is toggled
  }

  Future<void> handleZoomPreferenceIconTap() async {
    await toggleZoomPreference();
    getZoomPreference().then((value) {
      setState(() {
        zoomPreference = value;
      });
    });
    // Refresh the UI or perform any other actions after the direction is toggled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _returnToCameraPage();
            },
          )
        ],
      ),
      body: Column(
        children: [
          FutureBuilder(
            future: getCameraDirection(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                String direction = snapshot.data ?? "front";
                return SettingsCard(
                  title: 'Camera Direction',
                  icon: Icons.camera,
                  onTap: handleCameraDirectionIconTap,
                  subtitle: this.direction,
                );
              }
            },
          ),
          FutureBuilder(
            future: getZoomPreference(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                String zoomPreference = snapshot.data ?? "reset";
                return SettingsCard(
                  title: 'Zoom Preference',
                  icon: Icons.camera,
                  onTap: handleZoomPreferenceIconTap,
                  subtitle: this.zoomPreference,
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
