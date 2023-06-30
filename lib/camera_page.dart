import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_takes_app/components/curved_slider.dart';
import 'package:smart_takes_app/components/zoom_control.dart';
import 'package:smart_takes_app/pages/settings_page.dart';
import 'constants/shared_preferences_constants.dart';
import 'constants/widget_constants.dart';
import 'video_page.dart';

class CameraPage extends StatefulWidget {
  final String? cameraDirection;
  final String? zoomPreference;

  const CameraPage({Key? key, required this.cameraDirection, required this.zoomPreference})
      : super(key: key); // Update the constructor

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  String? cameraDirection;
  late final SharedPreferences prefs;

  bool _isLoading = true;
  bool _isRecording = false;
  bool _showFocusCircle = false;

  FlashMode flashMode = FlashMode.off;
  late CameraController _cameraController;
  ResolutionPreset _currentResolution = ResolutionPreset.max;
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _accelometerX = 0;
  double _accelometerY = 0;
  double _gyroscopeX = 0;
  double _gyroscopeY = 0;
  double _tapDownX = 0;
  double _tapDownY = 0;
  bool _inPreview = false;
  bool isFirstVideo = false;
  String _deviceOrientation = '';
  //bool _isVideoUsed = false;
  //bool _isFirstLoad = true;

  @override
  void initState() {
    /*gyroscopeEvents.listen((GyroscopeEvent event) {
      gyroscopeY = event.y;
      //Rotate down
      if (gyroscopeY > 2.5 && _isRecording == true && _inPreview == false) {
        _stopRecording();
      }
      //Rotate up
      else if (gyroscopeY < -2.5 && _isRecording == false && _inPreview == false) {
        _startRecording();
      }
    });*/

    print(widget.cameraDirection);
    _initCamera(
        widget.cameraDirection,
        widget.zoomPreference,
        _currentResolution);

    super.initState();
  }

  @override
  void dispose() {
    print('Disposing Camera');
    _cameraController.dispose();
    super.dispose();
  }

  void _initCamera(
      String? direction, String? zoomPreference, ResolutionPreset resolution) async {
    setState(() {
      _isLoading = true;
    });

    print('Creating Camera');
    prefs = await SharedPreferences.getInstance();
    _deviceOrientation = prefs.getString(kDeviceOrientation)!;

    CameraLensDirection cameraLensDirection;
    if(direction == 'front') {
      cameraLensDirection = CameraLensDirection.front;
    } else {
      cameraLensDirection = CameraLensDirection.back;
    }

    final cameras = await availableCameras();
    final cameraDirection =
    cameras.firstWhere((camera) => camera.lensDirection == cameraLensDirection);
    _cameraController = CameraController(cameraDirection, resolution);
    await _cameraController.initialize();
    await _cameraController.prepareForVideoRecording();

    if(_deviceOrientation == 'landscape') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
      ]);
      await _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
    }
    else if(_deviceOrientation == 'portrait') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await _cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    }

    //await _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
    await _cameraController.setExposureMode(ExposureMode.auto);
    await _cameraController.setFocusMode(FocusMode.auto);

    _minAvailableZoom = await _cameraController.getMinZoomLevel();
    _maxAvailableZoom = await _cameraController.getMaxZoomLevel();

    if(zoomPreference == 'reset') {
      _cameraController.setZoomLevel(1.0);
      _currentScale = 1.0;
      //prefs.setDouble('kZoomLevel', 1.0);
    } else if(zoomPreference == 'keep') {
      double zoomLevel = prefs.getDouble('kZoomLevel')!;
      _cameraController.setZoomLevel(zoomLevel);
      _currentScale = zoomLevel;
    }

    _initAccelerometerAndGyroscope();

    setState(() => _isLoading = false);
  }

  void _initAccelerometerAndGyroscope() {
    print('Starting Accelerometer and Gyroscope');
    gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroscopeX = event.x;
      _gyroscopeY = event.y;
    });

    accelerometerEvents.listen((AccelerometerEvent event) {
      _accelometerX = event.x;
      _accelometerY = event.y;
      //Rotate up landscape
      if (_accelometerX > 7.5 && _gyroscopeY > -0.5 && _isRecording == false && _inPreview == false && _deviceOrientation == 'landscape') {
        print(_gyroscopeY);
        _startRecording();
      }
      //Rotate Down landscape
      else if (_accelometerX < 6.5 && _isRecording == true && _inPreview == false && _deviceOrientation == 'landscape') {
        //print(_gyroscopeY);
        _stopRecording();
      }
      //Rotate up portrait
      else if (_accelometerY > 7 && _gyroscopeX < 0.5 && _isRecording == false && _inPreview == false && _deviceOrientation == 'portrait') {
        print(_accelometerY);
        _startRecording();
      }
      //Rotate down portrait
      else if (_accelometerY < 6.5 && _isRecording == true && _inPreview == false && _deviceOrientation == 'portrait') {
        print(_accelometerY);
        _stopRecording();
      }
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _inPreview = false;
    });
    print('Recording Video');
    //await _cameraController.prepareForVideoRecording();
    await _cameraController.startVideoRecording();
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _inPreview = true;
    });
    final file = await _cameraController.stopVideoRecording();
    print('Stop Recording');

    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) {
        return VideoPage(filePath: file.path, isFirstVideo: isFirstVideo);
      },
    );
    if(context.mounted) {
      await Navigator.pushReplacement(context, route);
    }
  }

  Future<void> _goToSettingsPage() async {
    setState(() {
      _inPreview = true;
    });

    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) {
        return SettingsPage();
      },
    );
    if(context.mounted) {
      await Navigator.pushReplacement(context, route);
    }
  }

  _toggleFlash() async {
    if (flashMode == FlashMode.off) {
      _cameraController.setFlashMode(FlashMode.torch);
      flashMode = FlashMode.always;
    } else {
      _cameraController.setFlashMode(FlashMode.off);
      flashMode = FlashMode.off;
    }
  }

  _toggleFramesPerSecond() async {}

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    double dragIntensity = details.scale;
    _currentScale = _baseScale * dragIntensity;

    if (_currentScale < _minAvailableZoom) {
      _cameraController.setZoomLevel(1.0);
      _currentScale = 1.0;
      prefs.setDouble('kZoomLevel', 1.0);
    }
    if (_currentScale > 1 && _currentScale < _maxAvailableZoom) {
      _cameraController.setZoomLevel(_currentScale);
      prefs.setDouble('kZoomLevel', _currentScale);
    }
    if (_currentScale >= _maxAvailableZoom) {
      _cameraController.setZoomLevel(_maxAvailableZoom);
      _currentScale = _maxAvailableZoom;
      prefs.setDouble('kZoomLevel', _maxAvailableZoom);
    }
  }

  void _onTapDown(TapDownDetails details) {
    _showFocusCircle = true;
    _tapDownX = details.localPosition.dx;
    _tapDownY = details.localPosition.dy;

    double fullWidth = MediaQuery.of(context).size.width;
    double cameraHeight = fullWidth * _cameraController.value.aspectRatio;

    double xp = _tapDownX / fullWidth;
    double yp = _tapDownY / cameraHeight;
    Offset point = Offset(xp, yp);

    _cameraController.setExposurePoint(point);
    _cameraController.setFocusPoint(point);

    setState(() {
      Future.delayed(const Duration(seconds: 2)).whenComplete(() {
        setState(() {
          _showFocusCircle = false;
        });
      });
    });
  }

  void handleZoomChanged(double value) {
    setState(() {
      _currentScale = value;
    });
  }

  Future<void> _deleteFiles() async {
    isFirstVideo = true;
    Directory appDir = await getApplicationDocumentsDirectory();
    _deleteFilesFromDirectory(appDir);
    String path = appDir.path;

    String directoryPath = '$path/Trimmer/';
    Directory trimmedVideos = Directory(directoryPath);
    _deleteFilesFromDirectory(trimmedVideos);

    directoryPath = '$path/camera/videos/';
    Directory savedVideos = Directory(directoryPath);
    _deleteFilesFromDirectory(savedVideos);

    print('App storage cleared.');
  }

  Future<void> _deleteFilesFromDirectory(Directory directory) async {
    List<FileSystemEntity> files = directory.listSync();

    // Delete each file in the directory
    for (FileSystemEntity file in files) {
      if (file is File) {
        await file.delete();
        print('FILE DELETED');
      }
    }
  }

  Future<void> _saveVideoToPhone() async {    // possibly could have problem when people are too quick from add video to previous to saveToPhone
    Directory appDir = await getApplicationDocumentsDirectory();
    var rawDocumentPath = appDir.path;
    var textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    var r = Random();
    String randomString = String.fromCharCodes(List.generate(32, (index) => r.nextInt(33) + 89));
    String outputPath = '$rawDocumentPath/REC_$randomString.mp4';

    FFmpegKit.execute('-y -f concat -safe 0 -i ${textFile.path} -c copy $outputPath').then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await GallerySaver.saveVideo(outputPath).then((_) {});
        var snackBar = SnackBar(content: Text('Saved Video to Phone and Files Deleted'));
        await ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await _deleteFiles();
        print("success!");
        //_videoIsUsed = true;
      } else if (ReturnCode.isCancel(returnCode)) {
        print("canceled");
        // CANCEL

      } else {
        var snackBar = SnackBar(content: Text('Error: Deleting files'));
        await ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await _deleteFiles();
        print("error");
        // ERROR

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Instructions Page'),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                var snackBar = SnackBar(content: Text('Exiting App'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
            ),
            /*IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteFiles();
              },
            ),*/
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveVideoToPhone();
                /*var snackBar = SnackBar(content: Text('Saved Video to Phone'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);*/
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _goToSettingsPage();
              }
            ),
          ],
        ),
        body: Container(
          child: const Text("Lift the screen to start recording."),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        )
            : Center(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onTapDown: _onTapDown,
                child: Stack(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                          /*AspectRatio(
                            aspectRatio:
                            _cameraController.value.aspectRatio,*/
                            child: CameraPreview(
                              _cameraController,
                              child: Padding(
                                padding:
                                const EdgeInsets.only(right: 15.0),
                                child: Stack(
                                  children: [
                                    /*Align(
                                            alignment: Alignment.centerRight,
                                            child: Transform.rotate(
                                              angle: math.pi / 2,
                                              child: SemiCircleSlider(
                                                initialValue: _currentScale,
                                                divisions: 11,
                                                onChanged: (value) async {
                                                  setState(() {
                                                    _currentScale = value;
                                                  });
                                                  await _cameraController!
                                                      .setZoomLevel(value);
                                                },
                                              ),
                                            ),
                                          ),*/
                                    /*Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                          icon: const Icon(
                                            Icons.settings,
                                            size: 30,
                                          ),
                                          onPressed: () async {
                                            final result =
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                  const SettingsPage()),
                                            );

                                            // Check if the camera direction has changed and rebuild the camera page
                                            if (result != null) {
                                              final cameraDirection =
                                              result as String;
                                              setState(() {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          CameraPage(
                                                              cameraDirection:
                                                              cameraDirection, isVideoUsed: false),
                                                  ));
                                              });
                                            }
                                          }),
                                    ),*/
                                    /*Align(
                                      alignment: Alignment.centerRight,
                                      child: FloatingActionButton(
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          _isRecording
                                              ? Icons.stop
                                              : Icons.fiber_manual_record,
                                        ),
                                        onPressed: () => _recordVideo(),
                                      ),
                                    ),*/
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showFocusCircle)
                      Positioned(
                          top: _tapDownY - 20,
                          left: _tapDownX - 20,
                          child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5))))
                  ],
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0.0, -2),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      height: 10,
                      child: Row(
                        children: [
                          /*Expanded(
                                  child: Slider(
                                    value: _currentScale,
                                    min: _minAvailableZoom,
                                    max: _maxAvailableZoom / 10,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white30,
                                    onChanged: (value) async {
                                      setState(() {
                                        _currentScale = value;
                                      });
                                      await _cameraController!
                                          .setZoomLevel(value);
                                    },
                                  ),
                                ),*/
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              /*SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FractionalTranslation(
                    translation: Offset(0.0, 1),
                    child: GestureDetector(
                      child: _currentResolution == ResolutionPreset.max
                          ? const Text("4k")
                          : const Text(
                        "HD",
                      ),
                      onTap: () {
                        if (_currentResolution == ResolutionPreset.max) {
                          _initCamera(widget.cameraDirection, widget.zoomPreference,
                              ResolutionPreset.veryHigh);
                          setState(() {
                            _currentResolution =
                                ResolutionPreset.veryHigh;
                          });
                        } else {
                          _initCamera(widget.cameraDirection, widget.zoomPreference,
                              ResolutionPreset.max);
                          setState(() {
                            _currentResolution = ResolutionPreset.max;  // just states that it is max when printed
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),*/
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        size: 20,
                        color: flashMode == FlashMode.off
                            ? Colors.white
                            : Colors.yellow,
                      ),
                      onPressed: () {
                        setState(() {
                          _toggleFlash();
                        });
                      }),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
