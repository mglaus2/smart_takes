import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_takes_app/constants/shared_preferences_constants.dart';

import 'camera_page.dart';
import 'constants/widget_constants.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(kCameraDirection) == null) {
    prefs.setString(kCameraDirection, "back");
  }
  var direction = prefs.getString(kCameraDirection);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
  ]);
  runApp(HomePage(cameraDirection: direction));
}

class HomePage extends StatefulWidget {
  final String? cameraDirection;
  const HomePage({Key? key, this.cameraDirection}) : super(key: key);

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
        cameraDirection: widget.cameraDirection,
      ),
    );
  }
}
