import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

class _CameraViewState extends State<CameraView> with TickerProviderStateMixin {
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
      duration: Duration(seconds: 10),
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

        // Navigate to the video preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPreviewScreen(videoPath: videoPath),
          ),
        );
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }
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
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
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
                      videoPath: '/videos'), // Provide the videoPath here
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
