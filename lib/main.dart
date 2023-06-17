import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_takes_app/constants/shared_preferences_constants.dart';

import 'camera_page.dart';
import 'constants/widget_constants.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(kCameraDirection) == null) {
    prefs.setString(kCameraDirection, "back");
  }
  if(prefs.getString(kZoomPreference) == null) {
    prefs.setString(kZoomPreference, 'reset');
  }
  if(prefs.getDouble('kZoomLevel') == 0.0) {
    prefs.setDouble('kZoomLevel', 1.0);
  }
  var direction = prefs.getString(kCameraDirection);
  var zoomPreference = prefs.getString(kZoomPreference);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
  ]);
  runApp(HomePage(cameraDirection: direction, zoomPreference: zoomPreference));
}

class HomePage extends StatefulWidget {
  final String? cameraDirection;
  final String? zoomPreference;

  const HomePage({Key? key, required this.cameraDirection, required this.zoomPreference}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: kThemeData,
      debugShowCheckedModeBanner: false,
      home: CameraPage(
        cameraDirection: widget.cameraDirection, zoomPreference: widget.zoomPreference
      ),
    );
  }
}
