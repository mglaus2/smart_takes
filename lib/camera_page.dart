import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isLoading = true;
  bool _isRecording = false;
  FlashMode flashMode = FlashMode.off;
  late CameraController _cameraController;
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
    ]);
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(back, ResolutionPreset.max);
    await _cameraController.initialize();
    await _cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
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

  _toggleFramesPerSecond() async {

  }

  void onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    var dragIntensity = details.scale;
    if (dragIntensity < 1) {
      // 1 is the minimum zoom level required by the camController's method, hence setting 1 if the user zooms out (less than one is given to details when you zoom-out/pinch-in).
      _currentScale = 1.0;
      _cameraController.setZoomLevel(1);
    } else if (dragIntensity > 1 && dragIntensity < _maxAvailableZoom) {
      // self-explanatory, that if the maxZoomLevel exceeds, you will get an error (greater than one is given to details when you zoom-in/pinch-out).
      _currentScale = dragIntensity;
      _cameraController.setZoomLevel(dragIntensity);
    } else {
      // if it does exceed, you can provide the maxZoomLevel instead of dragIntensity (this block is executed whenever you zoom-in/pinch-out more than the max zoom level).
      _currentScale = _maxAvailableZoom;
      _cameraController.setZoomLevel(_maxAvailableZoom);
    }

    /*setState(() {
      _currentScale = _baseScale * details.scale.clamp(_minAvailableZoom, _maxAvailableZoom);
    });*/
  }

  void onScaleEnd(ScaleEndDetails details) {
    _cameraController.setZoomLevel(_currentScale);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Center(
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            GestureDetector(
              onScaleStart: onScaleStart,
              onScaleUpdate: onScaleUpdate,
              onScaleEnd: onScaleEnd,
              child: AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              ),
            ),
            //CameraPreview(_cameraController),

            Padding(
              padding: const EdgeInsets.all(25),
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: Icon(_isRecording ? Icons.stop : Icons.circle),
                onPressed: () => _recordVideo(),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FloatingActionButton(
                  child: Icon(flashMode == FlashMode.off ? Icons.flashlight_off : Icons.flashlight_on),
                  onPressed: () {
                    setState(() {
                      _toggleFlash();
                    });
                  }
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: FloatingActionButton(
                    child: Icon(flashMode == FlashMode.off ? Icons.flashlight_off : Icons.flashlight_on),
                    onPressed: () {
                      setState(() {
                        _toggleFlash();
                      });
                    }
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
