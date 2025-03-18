import 'package:flutter/material.dart';
import '../../models/live_video.dart';
import '../../widgets/video/video_grid_item.dart';
import '../../utils/constants.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({Key? key}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  List<LiveVideo> _videos = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

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

    // Giả lập tải dữ liệu từ API
    await Future.delayed(const Duration(seconds: 1));

    // Tạo dữ liệu mẫu
    final mockVideos = [
      LiveVideo(
        id: '1',
        title: 'Chung kết Giải Pickleball Mùa Xuân 2023',
        imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball,1',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Trận chung kết đầy kịch tính của giải đấu mùa xuân 2023',
        isLive: false,
      ),
      LiveVideo(
        id: '2',
        title: 'Hướng dẫn kỹ thuật đánh Pickleball cơ bản',
        imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball,2',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        description: 'Các kỹ thuật cơ bản dành cho người mới chơi Pickleball',
        isLive: false,
      ),
      LiveVideo(
        id: '3',
        title: 'Giải Pickleball Hè 2023 - Bảng A',
        imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball,3',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Trận đấu vòng bảng A của giải Pickleball mùa hè 2023',
        isLive: true,
      ),
      LiveVideo(
        id: '4',
        title: 'Phân tích chiến thuật Pickleball chuyên sâu',
        imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball,4',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        description:
            'Phân tích chiến thuật chuyên sâu dành cho người chơi Pickleball nâng cao',
        isLive: false,
      ),
    ];

    setState(() {
      _videos = mockVideos;
      _isLoading = false;
    });
  }

  List<LiveVideo> _getFilteredVideos() {
    final searchQuery = _searchController.text.toLowerCase();

    if (searchQuery.isEmpty) return _videos;

    return _videos.where((video) {
      return video.title.toLowerCase().contains(searchQuery) ||
          (video.description?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVideos = _getFilteredVideos();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Video')),
      body: Column(
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
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredVideos.isEmpty
                    ? const Center(child: Text('Không có video nào'))
                    : RefreshIndicator(
                      onRefresh: _loadVideos,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(
                          UIConstants.defaultPadding,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredVideos.length,
                        itemBuilder: (context, index) {
                          return VideoGridItem(
                            video: filteredVideos[index],
                            onTap:
                                () => _navigateToVideoDetail(
                                  filteredVideos[index],
                                ),
                            onEdit:
                                () =>
                                    _showEditVideoDialog(filteredVideos[index]),
                            onDelete: () => _deleteVideo(filteredVideos[index]),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVideoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToVideoDetail(LiveVideo video) {
    // Chuyển đến màn hình chi tiết video
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(video.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(video.imageUrl, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Text(video.description ?? 'Không có mô tả'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${video.createdAt.day}/${video.createdAt.month}/${video.createdAt.year}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Trong thực tế, mở trình phát video
                  Navigator.pop(context);
                },
                child: const Text('Phát video'),
              ),
            ],
          ),
    );
  }

  void _showAddVideoDialog() {
    // Hiển thị dialog thêm video mới
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thêm video mới'),
            content: const SizedBox(
              width: 400,
              child: Text('Chức năng này sẽ được triển khai sau'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Thêm'),
              ),
            ],
          ),
    );
  }

  void _showEditVideoDialog(LiveVideo video) {
    // Hiển thị dialog chỉnh sửa video
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chỉnh sửa video'),
            content: const SizedBox(
              width: 400,
              child: Text('Chức năng này sẽ được triển khai sau'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  void _deleteVideo(LiveVideo video) {
    // Hiển thị dialog xác nhận xóa
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa video "${video.title}" không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Trong thực tế, gọi API để xóa video
                  setState(() {
                    _videos.removeWhere((v) => v.id == video.id);
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Đã xóa video')));
                },
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }
}
