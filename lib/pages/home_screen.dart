import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:streamy/widgets/video_player_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VideoPlayerManager _videoManager = VideoPlayerManager();
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> videoData = [
    {
      'url':
          'https://jfeddcbpwoakhalxcqpx.supabase.co/storage/v1/object/public/streamy//videoplayback.mp4',
      'tags': ['Song', 'English'],
      'title': 'ACM Anthem',
    },
    {
      'url':
          'https://jfeddcbpwoakhalxcqpx.supabase.co/storage/v1/object/public/streamy//avengers.mp4',
      'tags': ['Trailer', 'English'],
      'title': 'Avengers Trailer',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    try {
      await _videoManager.initializeControllers(videoData);
    } catch (e) {
      debugPrint('Error initializing videos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Color(0xFFE50914),
        ), // Changes user-typed text color
        decoration: InputDecoration(
          hintText: 'Search by tags...',
          hintStyle: const TextStyle(
            color: Colors.redAccent,
          ), // Changes placeholder text color
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.redAccent,
          ), // Search icon color
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[200], // Background color

          labelStyle: const TextStyle(
            color: Color(0xFFE50914),
          ), // Changes label color
        ),
        onChanged: (value) {
          setState(() {
            _videoManager.filterVideos(value);
          });
        },
      ),
    );
  }

  Widget _buildVideoControls(int index, VideoPlayerController controller) {
    return AnimatedOpacity(
      opacity: _videoManager.showControls[index] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFE50914),
                bufferedColor: Colors.white70,
                backgroundColor: Colors.white24,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () => _videoManager.togglePlay(index),
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: controller.value.volume,
                      onChanged:
                          (value) => _videoManager.setVolume(index, value),
                      activeColor: const Color(0xFFE50914),
                      inactiveColor: Colors.white70,
                    ),
                  ),
                  Text(
                    '${controller.value.position.inMinutes}:${(controller.value.position.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(int index) {
    if (_isLoading) {
      return const Card(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final error = _videoManager.getError(index);
    if (error.isNotEmpty) {
      return Card(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Failed to load video',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                TextButton(
                  onPressed: _initializeVideos,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_videoManager.isInitialized(index)) {
      return const Card(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final controller = _videoManager.controllers[index];
    final videoTags = _videoManager.tags[index];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          StreamBuilder<int>(
            stream: _videoManager.playingStream,
            builder: (context, snapshot) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _videoManager.toggleControls(index);
                        setState(() {}); // Force rebuild
                      },
                      child: VideoPlayer(controller),
                    ),
                  ),
                  _buildVideoControls(index, controller),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoData[index]['title'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children:
                      videoTags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(
                                  color: Color(0xFFE50914), // Red text for tags
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor:
                                  Colors.grey[300], // Light grey background
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color(0xFFE50914),
                                ), // Red border
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STREAMY',
          style: TextStyle(color: Color(0xFFE50914)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child:
                videoData.isEmpty
                    ? const Center(child: Text('No videos available'))
                    : ListView.builder(
                      itemCount: _videoManager.filteredIndices.length,
                      itemBuilder:
                          (context, index) => _buildVideoCard(
                            int.parse(_videoManager.filteredIndices[index]),
                          ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _videoManager.dispose();
    super.dispose();
  }
}
