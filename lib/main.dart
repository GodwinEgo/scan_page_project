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

class _CameraViewState extends State<CameraView> {
  late CameraController _cameraController;
  late Future<void> _cameraInitializeFuture;
  bool cameraControllerInitialized = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    super.dispose();
  }

  Future<void> _startVideoRecording() async {
    if (!_cameraController.value.isRecordingVideo) {
      try {
        await _cameraController.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        await Future.delayed(const Duration(seconds: 10));
        await _stopVideoRecording();
      } catch (e) {
        print('Error starting video recording: $e');
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController.value.isRecordingVideo) {
      try {
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
      body: FutureBuilder<void>(
        future: _cameraInitializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;

            return Stack(
              children: [
                CameraPreview(_cameraController),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isRecording) {
            _stopVideoRecording();
          } else {
            _startVideoRecording();
          }
        },
        child: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
