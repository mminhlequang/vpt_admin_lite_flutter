import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../widgets/video/video_list_item.dart';
import '../../utils/constants.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'video_detail_screen.dart';
import 'create_video_screen.dart';

Future<List<Video>> fetchVideos() async {
  List<Video> videosList = [];
  // Gọi API thực tế để lấy danh sách video
  final response = await Dio().get('https://familyworld.xyz/api/videos');

  if (response.statusCode == 200) {
    try {
      final data = json.decode(jsonEncode(response.data));

      // Chuyển đổi dữ liệu từ API thành danh sách Video
      if (data is List) {
        videosList = data.map((item) => Video.fromJson(item)).toList();
      } else if (data['data'] is List) {
        videosList =
            (data['data'] as List).map((item) => Video.fromJson(item)).toList();
      }
    } catch (e) {
      print('Lỗi khi phân tích dữ liệu: $e');
    }

    return videosList;
  } else {
    print('Không thể tải dữ liệu từ API: ${response.statusCode}');
    return videosList;
  }
}

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Video> _videos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    _videos = await fetchVideos();
    setState(() {
      _isLoading = false;
    });
  }

  List<Video> _getFilteredVideos() {
    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isEmpty) {
      return _videos;
    }

    return _videos.where((video) {
      return video.name.toLowerCase().contains(searchQuery) ||
          video.type.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý video')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm video',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(child: _buildVideoList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateVideoScreen()),
    ).then((result) {
      // Nếu tạo video thành công, cập nhật lại danh sách
      if (result == true) {
        _loadVideos();
      }
    });
  }

  Widget _buildVideoList() {
    final filteredVideos = _getFilteredVideos();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredVideos.isEmpty) {
      return const Center(child: Text('Không có video nào'));
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth =
              (constraints.maxWidth - UIConstants.defaultPadding * 2 - 16) / 2;
          return Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
                  filteredVideos.map((video) {
                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () => _navigateToVideoDetail(video),
                        child: VideoListItem(video: video),
                      ),
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _navigateToVideoDetail(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoDetailScreen(video: video)),
    ).then((_) {
      // Cập nhật lại danh sách khi quay về từ màn hình chi tiết
      _loadVideos();
    });
  }
}
