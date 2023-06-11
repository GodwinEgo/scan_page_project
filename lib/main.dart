import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:stacked/stacked.dart';
import 'dart:ui';

import 'video_preview_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera View',
      theme: ThemeData.dark(),
      home: CameraView(),
    );
  }
}

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late Future<void> _cameraInitializeFuture;
  bool cameraControllerInitialized = false;
  bool _isRecording = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: 1).animate(_progressController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _stopVideoRecording();
            }
          });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _cameraInitializeFuture = _cameraController.initialize();
    if (mounted) {
      setState(() {});
    }
    cameraControllerInitialized = true;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      try {
        await _cameraController.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        _progressController.forward();
      } catch (e) {
        print('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController.value.isRecordingVideo) {
      try {
        _progressController.reset();
        _progressController.stop();
        final XFile videoFile = await _cameraController.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });

        final String videoPath = videoFile.path;
        print('Video saved at: $videoPath');

        // Send video to server
        _sendVideoToServer(videoPath);
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }
  }

  void _sendVideoToServer(String videoPath) {
    // Send the video file to the server
    // TODO: Implement your server communication logic here
    print('Sending video to server: $videoPath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera View'),
      ),
      body: FutureBuilder<void>(
        future: _cameraInitializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;

            return Stack(
              children: [
                CameraPreview(_cameraController),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Container(
                            width: size.width,
                            height: size.width / deviceRatio,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: _progressAnimation.value * 200,
                          left: 0,
                          right: 0,
                          height: 2,
                          child: Container(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              // Navigate to the video preview screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPreviewScreen(
                    videoPath: '/videos', // Provide the videoPath here
                  ),
                ),
              );
            },
            child: Icon(Icons.preview),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              if (_isRecording) {
                _stopVideoRecording();
              } else {
                _startVideoRecording();
              }
            },
            child: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}
