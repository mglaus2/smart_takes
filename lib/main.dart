import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'camera_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double y = 0;

  @override
  void initState() {
    gyroscopeEvents.listen((GyroscopeEvent event) {
      y = event.y;

      if(y > 2.5 || y < -2.5) {
        setState(() {});
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    if(y > 0) {
      return Container(
        color: Colors.blue,
      );
    } else {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CameraPage(),
      );
    }
  }
}
