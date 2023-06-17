import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_takes_app/constants/shared_preferences_constants.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:video_trimmer/video_trimmer.dart';

import 'camera_page.dart';

class VideoPage extends StatefulWidget {
  final String filePath;
  final bool isFirstVideo;

  VideoPage({Key? key, required this.filePath, required this.isFirstVideo}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  //late VideoPlayerController _videoPlayerController;
  final Trimmer _trimmer = Trimmer();
  var tempDir;
  var rawDocumentPath;
  var outputPath;
  var textFile;

  String path = '';

  bool isVideoUsed = false;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;

  bool _videoIsUsed = false;

  @override
  void dispose() {
    //_videoPlayerController.dispose();
    _trimmer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadVideo();
    _createFiles();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: File(widget.filePath));
  }

  Future<void> _createFiles() async {
    tempDir = await getApplicationDocumentsDirectory();
    rawDocumentPath = tempDir.path;
    /*path = rawDocumentPath.substring(40, 76);
    print(rawDocumentPath);       // document path is different everytime you start app, therefore not allowing you to access previous videos when app closes
    print(path);*/
    textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    print('Files Created!');
  }

  Future<void> _returnToCamera() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var direction = prefs.getString(kCameraDirection);
    var zoomPreference = prefs.getString(kZoomPreference);
    final route = MaterialPageRoute(fullscreenDialog: true,
      builder: (_) {
        return CameraPage(cameraDirection: direction, zoomPreference: zoomPreference);
      },
    );
    await Navigator.pushReplacement(context, route).then((value) {});
  }

  /*Future _initVideoPlayer() async {
    /*_videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();*/
    tempDir = await getApplicationDocumentsDirectory();
    rawDocumentPath = tempDir.path;
    path = rawDocumentPath.substring(40, 76);
    print(rawDocumentPath);       // document path is different everytime you start app, therefore not allowing you to access previous videos when app closes
    print(path);
    textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    print('Files Created!');
  }*/

  Future<void> _removeCurrentVideo() async {
    if(!_videoIsUsed) {
      await File(widget.filePath).delete();
      print('file deleted');
    }

    _returnToCamera();
  }

  void _addToPreviousVideo() async {
    print('Compare file paths:');
    print(widget.filePath);
    await _trimmer.saveTrimmedVideo(startValue: _startValue, endValue: _endValue, onSave: (String? outputPath) { _saveVideoToFile(outputPath); });
  }

  Future<void> _saveVideoToFile(String? path) async {
    String filePath = path!;
    if(widget.isFirstVideo) {
      print("first video");
      textFile.writeAsString('file $filePath \n', mode: FileMode.write);
    }
    else {
      textFile.writeAsString('file $filePath \n', mode: FileMode.append);
    }

    GallerySaver.saveVideo(filePath).then((_) {});
    List<String> files = await textFile.readAsLines();
    files.forEach((String file) => print(file));
    print("finished");

    _videoIsUsed = true;
  }

  Future<void> _saveVideoToPhone() async {
    var r = Random();
    String randomString = String.fromCharCodes(List.generate(32, (index) => r.nextInt(33) + 89));
    outputPath = '$rawDocumentPath/REC_$randomString.mp4';

    /*List<String> fileContent = await textFile.readAsLines();
    for (var fileName in fileContent) {
      fileName = fileName.replaceAll('file ', '');
      print(fileName);
      fileName = fileName.substring(0, 45) + path + fileName.substring(76, fileName.length);
      await File(fileName).delete();
    }*/

    FFmpegKit.execute('-y -f concat -safe 0 -i ${textFile.path} -c copy $outputPath').then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await GallerySaver.saveVideo(outputPath).then((_) {});
        print("success!");
        _videoIsUsed = true;
      } else if (ReturnCode.isCancel(returnCode)) {
        print("canceled");
        // CANCEL

      } else {
        print("error");
        // ERROR

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              _removeCurrentVideo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _addToPreviousVideo();
              var snackBar = SnackBar(content: Text('Added Video to Previous'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveVideoToPhone();
              var snackBar = SnackBar(content: Text('Saved Video to Phone'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
          TextButton(
            child: _isPlaying
                ? const Icon(
              Icons.pause,
            )
                : const Icon(
              Icons.play_arrow,
            ),
            onPressed: () async {
              bool playbackState = await _trimmer.videoPlaybackControl(
                startValue: _startValue,
                endValue: _endValue,
              );
              setState(() {
                _isPlaying = playbackState;
              });
            },
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: VideoViewer(trimmer: _trimmer),
      bottomNavigationBar: TrimViewer(
        trimmer: _trimmer,
        viewerHeight: 50.0,
        viewerWidth: MediaQuery.of(context).size.width,
        maxVideoLength: const Duration(seconds: 999999),
        onChangeStart: (value) => _startValue = value,
        onChangeEnd: (value) => _endValue = value,
        onChangePlaybackState: (value) =>
            setState(() => _isPlaying = value),
      ),
      /*FutureBuilder(
        future: _initVideoPlayer(),
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return VideoPlayer(_videoPlayerController);
          }
        },
      ),*/
    );
  }
}

