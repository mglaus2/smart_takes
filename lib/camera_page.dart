import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_page.dart';

const TextStyle cameraStyle = TextStyle(color: Colors.white);

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
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
  double x = 0;
  double y = 0;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
    ]);
    _initCamera(CameraLensDirection.back, _currentResolution);
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  _initCamera(
      CameraLensDirection direction, ResolutionPreset resolution) async {
    setState(() {
      _isLoading = true;
    });
    final cameras = await availableCameras();
    final cameraDirection =
    cameras.firstWhere((camera) => camera.lensDirection == direction);
    _cameraController = CameraController(cameraDirection, resolution);
    await _cameraController.initialize();
    await _cameraController
        .lockCaptureOrientation(DeviceOrientation.landscapeRight);
    await _cameraController.setExposureMode(ExposureMode.auto);
    await _cameraController.setFocusMode(FocusMode.auto);

    _minAvailableZoom = await _cameraController.getMinZoomLevel();
    _maxAvailableZoom = await _cameraController.getMaxZoomLevel();

    setState(() => _isLoading = false);
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      final route = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPage(filePath: file.path),
      );
      Navigator.push(context, route);
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() => _isRecording = true);
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
    }
    if (_currentScale > 1 && _currentScale < _maxAvailableZoom) {
      _cameraController.setZoomLevel(_currentScale);
    }
    if (_currentScale >= _maxAvailableZoom) {
      _cameraController.setZoomLevel(_maxAvailableZoom);
      _currentScale = _maxAvailableZoom;
    }
  }

  void _onTapDown(TapDownDetails details) {
    _showFocusCircle = true;
    x = details.localPosition.dx;
    y = details.localPosition.dy;

    double fullWidth = MediaQuery.of(context).size.width;
    double cameraHeight = fullWidth * _cameraController.value.aspectRatio;

    double xp = x / fullWidth;
    double yp = y / cameraHeight;
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

  @override
  Widget build(BuildContext context) {
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
                        AspectRatio(
                          aspectRatio:
                          _cameraController.value.aspectRatio,
                          child: CameraPreview(
                            _cameraController,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, 0.0),
                                child: FloatingActionButton(
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    _isRecording
                                        ? Icons.stop
                                        : Icons.fiber_manual_record,
                                  ),
                                  onPressed: () => _recordVideo(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showFocusCircle)
                    Positioned(
                        top: y - 20,
                        left: x - 20,
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
                        Expanded(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: FractionalTranslation(
                  translation: Offset(0.0, 1),
                  child: GestureDetector(
                    child: _currentResolution == ResolutionPreset.max
                        ? const Text("4k", style: cameraStyle)
                        : const Text(
                      "HD",
                      style: cameraStyle,
                    ),
                    onTap: () {
                      if (_currentResolution == ResolutionPreset.max) {
                        _initCamera(CameraLensDirection.back,
                            ResolutionPreset.veryHigh);
                        setState(() {
                          _currentResolution = ResolutionPreset.veryHigh;
                        });
                      } else {
                        _initCamera(CameraLensDirection.back,
                            ResolutionPreset.max);
                        setState(() {
                          _currentResolution = ResolutionPreset.max;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
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
