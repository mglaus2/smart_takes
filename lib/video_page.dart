import 'dart:io';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

import 'globals.dart' as globals;

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  //final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  late VideoPlayerController _videoPlayerController;
  var tempDir;
  String rawDocumentPath = "";
  var outputPath;
  var textFile;

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
    tempDir = await getTemporaryDirectory();
    rawDocumentPath = tempDir.path;
    outputPath = '$rawDocumentPath/output.mp4';
    textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    print('Files Created!');
  }

  void _addToPreviousVideo() async {
    //IMAGE PICKER USING IPHONE CAMERA TO TAKE VIDEO
    /*final ImagePicker picker = ImagePicker();
    final XFile? galleryVideo = await picker.pickVideo(source: ImageSource.gallery);
    final XFile? cameraVideo = await picker.pickVideo(source: ImageSource.camera);*/

    String filePath = widget.filePath;
    if(globals.isFirstVideo) {
      print("first video");
      textFile.writeAsString('file $filePath \n', mode: FileMode.write);
      globals.isFirstVideo = false;
    }
    else {
      textFile.writeAsString('file $filePath \n', mode: FileMode.append);
    }

    print("finished");
  }

  void _saveVideoToPhone() {
    FFmpegKit.execute('-y -f concat -safe 0 -i ${textFile.path} -c copy $outputPath').then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        GallerySaver.saveVideo(outputPath).then((_) {});
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
            onPressed: () => _addToPreviousVideo(),
          ),
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveVideoToPhone(),
          )
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
