import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoPlayerManager {
  List<VideoPlayerController> _controllers = [];
  List<bool> _initialized = [];
  List<String> _errors = [];
  List<List<String>> _tags = [];
  List<String> _filteredIndices = [];
  List<bool> _showControls = [];
  List<Timer?> _controlTimers = [];

  final StreamController<int> _playingController =
      StreamController<int>.broadcast();
  Stream<int> get playingStream => _playingController.stream;

  List<VideoPlayerController> get controllers =>
      List.unmodifiable(_controllers);
  List<bool> get initialized => List.unmodifiable(_initialized);
  List<String> get errors => List.unmodifiable(_errors);
  List<List<String>> get tags => List.unmodifiable(_tags);
  List<String> get filteredIndices => List.unmodifiable(_filteredIndices);
  List<bool> get showControls => List.unmodifiable(_showControls);

  bool isInitialized(int index) {
    return index >= 0 && index < _initialized.length && _initialized[index];
  }

  void filterVideos(String query) {
    if (query.isEmpty) {
      _filteredIndices = List.generate(
        _controllers.length,
        (index) => index.toString(),
      );
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    _filteredIndices =
        List.generate(_controllers.length, (index) => index.toString()).where((
          index,
        ) {
          final videoTags = _tags[int.parse(index)];
          return videoTags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
        }).toList();
  }

  void setVolume(int index, double volume) {
    if (index >= 0 && index < _controllers.length && _initialized[index]) {
      _controllers[index].setVolume(volume);
    }
  }

  String getError(int index) {
    if (index >= 0 && index < _errors.length) {
      return _errors[index];
    }
    return '';
  }

  Future<void> initializeControllers(
    List<Map<String, dynamic>> videoData,
  ) async {
    disposeControllers();

    if (videoData.isEmpty) {
      return;
    }

    _initialized = List.filled(videoData.length, false);
    _errors = List.filled(videoData.length, '');
    _tags = videoData.map((data) => List<String>.from(data['tags'])).toList();
    _filteredIndices = List.generate(
      videoData.length,
      (index) => index.toString(),
    );
    _showControls = List.filled(videoData.length, false);
    _controlTimers = List.filled(videoData.length, null);

    _controllers = List.generate(
      videoData.length,
      (index) =>
          VideoPlayerController.networkUrl(Uri.parse(videoData[index]['url'])),
    );

    for (int i = 0; i < videoData.length; i++) {
      try {
        await _controllers[i].initialize();
        _controllers[i].setLooping(true);
        _initialized[i] = true;
        _playingController.add(i);
      } catch (error) {
        _errors[i] = error.toString();
      }
    }
  }

  void togglePlay(int index) {
    if (index < 0 || index >= _controllers.length || !_initialized[index]) {
      return;
    }

    try {
      if (_controllers[index].value.isPlaying) {
        _controllers[index].pause();
      } else {
        for (var i = 0; i < _controllers.length; i++) {
          if (i != index &&
              _initialized[i] &&
              _controllers[i].value.isPlaying) {
            _controllers[i].pause();
          }
        }
        _controllers[index].play();
      }
      _playingController.add(index);
    } catch (error) {
      _errors[index] = error.toString();
    }
  }

  void toggleControls(int index) {
    if (index >= 0 && index < _showControls.length) {
      _controlTimers[index]?.cancel();
      _showControls[index] = !_showControls[index];
      _playingController.add(index);

      if (_showControls[index]) {
        _controlTimers[index] = Timer(const Duration(seconds: 3), () {
          _showControls[index] = false;
          _playingController.add(index);
        });
      }
    }
  }

  void disposeControllers() {
    for (var timer in _controlTimers) {
      timer?.cancel();
    }
    _controlTimers.clear();

    for (var controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    _initialized.clear();
    _errors.clear();
    _tags.clear();
    _filteredIndices.clear();
    _showControls.clear();
  }

  void dispose() {
    disposeControllers();
    _playingController.close();
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleControls;

  const VideoPlayerWidget({
    required this.controller,
    required this.showControls,
    required this.onTogglePlay,
    required this.onToggleControls,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onToggleControls,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        if (showControls)
          Positioned(
            bottom: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    size: 50,
                    color: Colors.white,
                  ),
                  onPressed: onTogglePlay,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class VideoDemoApp extends StatefulWidget {
  const VideoDemoApp({super.key});

  @override
  State<VideoDemoApp> createState() => _VideoDemoAppState();
}

class _VideoDemoAppState extends State<VideoDemoApp> {
  late VideoPlayerManager _manager;
  final List<Map<String, dynamic>> _videoData = [
    {
      'url': '',
      'tags': ['tag'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _manager = VideoPlayerManager();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    await _manager.initializeControllers(_videoData);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Video Player Demo',
            style: TextStyle(
              fontFamily: "NetflixFont",
              fontSize: 40,
              color: Colors.red, // Netflix-style red
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child:
              _manager.controllers.isNotEmpty && _manager.initialized[0]
                  ? StreamBuilder<int>(
                    stream: _manager.playingStream,
                    builder: (context, snapshot) {
                      return VideoPlayerWidget(
                        controller: _manager.controllers[0],
                        showControls: _manager.showControls[0],
                        onTogglePlay: () => _manager.togglePlay(0),
                        onToggleControls: () => _manager.toggleControls(0),
                      );
                    },
                  )
                  : const CircularProgressIndicator(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _manager.togglePlay(0);
            });
          },
          child: Icon(
            _manager.controllers.isNotEmpty &&
                    _manager.controllers[0].value.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }
}

void main() {
  runApp(const VideoDemoApp());
}
