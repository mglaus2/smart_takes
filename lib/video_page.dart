import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class VideoPage extends StatefulWidget {
  final String filePath;
  final bool isFirstVideo;

  VideoPage({Key? key, required this.filePath, required this.isFirstVideo}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  //final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  late VideoPlayerController _videoPlayerController;
  var tempDir;
  var rawDocumentPath;
  var outputPath;
  var textFile;

  String path = '';

  bool isVideoUsed = false;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
    await _videoPlayerController.initialize();
    await _videoPlayerController.setLooping(true);
    await _videoPlayerController.play();
    tempDir = await getApplicationDocumentsDirectory();
    rawDocumentPath = tempDir.path;
    path = rawDocumentPath.substring(40, 76);
    String testPath = DateTime.now().millisecondsSinceEpoch.toString();
    print(rawDocumentPath);       // document path is different everytime you start app, therefore not allowing you to access previous videos when app closes
    print(path);
    print(testPath);
    textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    print('Files Created!');
  }

  void _addToPreviousVideo() async {
    String filePath = widget.filePath;
    if(widget.isFirstVideo) {
      print("first video");
      textFile.writeAsString('file /var/mobile/Containers/Data/Application/$path/Documents/camera/videos/REC_5B1C8F69-2AD4-4B5E-B4D7-D303269AE047.mp4 \n', mode: FileMode.write);
    }
    else {
      textFile.writeAsString('file $filePath \n', mode: FileMode.append);
    }

    GallerySaver.saveVideo(filePath).then((_) {});
    List<String> files = await textFile.readAsLines();
    files.forEach((String file) => print(file));
    print("finished");
    Navigator.pop(context, true);
  }

  void _saveVideoToPhone() {
    var r = Random();
    String randomString = String.fromCharCodes(List.generate(32, (index) => r.nextInt(33) + 89));
    outputPath = '$rawDocumentPath/REC_$randomString.mp4';
    FFmpegKit.execute('-y -f concat -safe 0 -i ${textFile.path} -c copy $outputPath').then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        GallerySaver.saveVideo(outputPath).then((_) {});
        Navigator.pop(context, true);
        print("success!");
        // SUCCESS

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
        ],
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder(
        future: _initVideoPlayer(),
        builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return VideoPlayer(_videoPlayerController);
          }
        },
      ),
    );
  }
}

