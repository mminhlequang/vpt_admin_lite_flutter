import 'package:flutter/material.dart';
import '../../models/live_video.dart';
import '../../utils/constants.dart';

class VideoDetailScreen extends StatefulWidget {
  final LiveVideo? video;

  const VideoDetailScreen({Key? key, this.video}) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late LiveVideo _video;
  bool _isLoading = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _video = widget.video!;
    } else {
      _loadVideoData();
    }
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
    });

    // Giả lập tải dữ liệu từ API
    await Future.delayed(const Duration(seconds: 1));

    // Ví dụ dữ liệu
    final video = LiveVideo(
      id: '1',
      title: 'Chung kết Giải Pickleball Mùa Xuân 2023',
      imageUrl: 'https://source.unsplash.com/random/800x600/?pickleball,1',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      description:
          'Trận chung kết đầy kịch tính của giải đấu mùa xuân 2023 giữa đội A và đội B. Trận đấu diễn ra căng thẳng với nhiều tình huống đáng chú ý.',
      isLive: false,
    );

    setState(() {
      _video = video;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết video')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildVideoDetail(),
    );
  }

  Widget _buildVideoDetail() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoPlayer(),
          Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoInfo(),
                const SizedBox(height: 16),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildActions(),
                const SizedBox(height: 24),
                _buildRelatedVideos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
            child: Container(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    _video.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (!_isPlaying)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_video.isLive)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _video.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Ngày đăng: ${_formatDate(_video.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.visibility, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('1,234 lượt xem', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mô tả',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(_video.description ?? 'Không có mô tả'),
            const SizedBox(height: 16),
            // Thêm thông tin về trận đấu (giả lập)
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Thông tin trận đấu:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildInfoRow('Giải đấu:', 'Giải Pickleball Mùa Xuân 2023'),
                _buildInfoRow('Đội 1:', 'Nguyễn A & Trần B'),
                _buildInfoRow('Đội 2:', 'Lê C & Phạm D'),
                _buildInfoRow('Kết quả:', '21-18, 19-21, 21-15'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.share,
          label: 'Chia sẻ',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chức năng chia sẻ sẽ được triển khai sau'),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Chỉnh sửa',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chức năng chỉnh sửa sẽ được triển khai sau'),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.delete,
          label: 'Xóa',
          onPressed: () {
            _showDeleteConfirmation();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa video "${_video.title}" không?',
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
                  Navigator.pop(context);
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

  Widget _buildRelatedVideos() {
    // Giả lập danh sách video liên quan
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video liên quan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://source.unsplash.com/random/800x600/?pickleball,${index + 2}',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Video giải đấu Pickleball ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${10 * (index + 1)}/${3 + index % 2}/2023',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
