import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'dart:async';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;

  const VideoPreviewScreen({required this.videoPath});

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  double progressValue = 0.0;
  int totalTime = 10;
  int currentTime = 0;
  Timer? time;
  bool timerCompleted = false;
  bool retryVisible = false;
  String uploadButtonText = 'Upload Video';

  ChewieController? _chewieController;
  bool _uploading = false;
  List<dynamic> _scores = [];

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    startTime();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    time?.cancel();
    super.dispose();
  }

  void startTime() {
    time = Timer.periodic(Duration(seconds: 1), (Timer time) {
      setState(() {
        retryVisible = false;
        if (currentTime < totalTime) {
          currentTime++;
          progressValue = currentTime / totalTime;
        } else {
          time.cancel();
          timerCompleted = true;
        }
      });
    });
  }

  Future<void> _initializeVideoPlayer() async {
    final videoPlayerController =
        VideoPlayerController.file(File(widget.videoPath));
    await videoPlayerController.initialize();

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        allowMuting: false,
        aspectRatio: videoPlayerController.value.aspectRatio,
        showControls: true,
        placeholder: Container(),
      );
    });
  }

  Future<void> _uploadVideo() async {
    print(widget.videoPath.toString());
    setState(() {
      _uploading = true;
    });

    try {
      String apiUrl = '/video';

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(widget.videoPath),
      });

      Dio dio = Dio();
      Response response = await dio.post(apiUrl, data: formData);

      if (response.statusCode == 200) {
        // File uploaded successfully
        Map<String, dynamic> responseData = response.data;
        List<dynamic> scores = responseData['scores'];

        setState(() {
          _scores = scores;
        });
      } else {
        // Failed to upload file
        print('Upload failed with status: ${response.statusCode}');
        setState(() {
          retryVisible = true;
        });
      }
    } catch (e) {
      // Error occurred during file upload
      print('Error uploading file: $e');
      setState(() {
        retryVisible = true;
      });
    }

    setState(() {
      _uploading = false;
    });
  }

  void uploadButtonFunction() {
    setState(() {
      _uploading ? null : _uploadVideo;
    });
    //_uploading ? null : _uploadVideo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Preview'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
                    controller: _chewieController!,
                  )
                : Center(
                    child: _chewieController != null &&
                            _chewieController!
                                .videoPlayerController.value.hasError
                        ? Text('Error loading video')
                        : CircularProgressIndicator(),
                  ),

            SizedBox(height: 32.0),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _uploading
                        ? null
                        : () {
                            if (retryVisible) {
                              // Retry button pressed, restart the process
                              setState(() {
                                retryVisible = false;
                                uploadButtonText = 'Upload Video';
                                startTime();
                              });
                            } else {
                              // Upload button pressed
                              _uploadVideo();
                            }
                          },
                    child: _uploading
                        ? CircularProgressIndicator()
                        : Text(retryVisible ? 'Retry' : uploadButtonText),
                  ),
                ],
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Retake Video'),
                  ),
                ],
              ),
            ]),

            // SizedBox(height: 16.0),
            // Text(
            //     timerCompleted? '':'Please wait it may take a while, \nRetry in ${totalTime-currentTime} seconds'
            // ),

            SizedBox(height: 16.0),
            if (_scores.isNotEmpty)
              Column(
                children: [
                  Text('Results:',
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _scores.length,
                    itemBuilder: (context, index) {
                      String score = _scores[index];

                      return ListTile(
                        title: Image.network(score),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
