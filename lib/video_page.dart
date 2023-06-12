import 'dart:io';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:video_trimmer/video_trimmer.dart';

import 'globals.dart' as globals;

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  var tempDir;
  String rawDocumentPath = "";
  String outputPath = "";
  var textFile;


  void _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    String? _value;

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

    GallerySaver.saveVideo(outputPath);
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: File(widget.filePath));
    print("loading video");
  }

  void _addToPreviousVideo() async {
    String filePath = widget.filePath;
    if(globals.isFirstVideo) {
      print("first video");
      textFile.writeAsString('file $filePath \n', mode: FileMode.write);
      globals.isFirstVideo = false;
    }
    else {
      textFile.writeAsString('file $filePath \n', mode: FileMode.append);
    }

    GallerySaver.saveVideo(filePath).then((_) {});
    print("finished");
  }



  Future<void> _loadFilePathNames() async {
    tempDir = await getTemporaryDirectory();
    rawDocumentPath = tempDir.path;
    outputPath = '$rawDocumentPath/output.mp4';
    textFile = File('$rawDocumentPath/smart_takes_text_file.txt');
    print('Files Created!');
  }

  @override
  void initState() {
    super.initState();

    _loadFilePathNames();
    _loadVideo();
  }

  @override
  void dispose() {
    _trimmer.dispose();
    print("disposing variables");
    super.dispose();
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
              _saveVideo();
              var snackBar = SnackBar(content: Text('Saved Video to Phone'));
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
          TextButton(
            child: _isPlaying
                ? Icon(
              Icons.pause,
            )
                : Icon(
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
        onChangeStart: (value) => _startValue = value,
        onChangeEnd: (value) => _endValue = value,
        onChangePlaybackState: (value) =>
            setState(() => _isPlaying = value),
      ),
    );
  }
}

