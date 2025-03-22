import 'package:flutter/material.dart';
import 'package:internal_core/internal_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vpt_admin_lite_flutter/utils/utils.dart';
import 'package:vpt_admin_lite_flutter/widgets/player/player_list_item.dart';
import '../../utils/constants.dart';
import '../../models/video.dart';
import 'edit_video_screen.dart';
import 'package:dio/dio.dart';

class VideoDetailScreen extends StatefulWidget {
  final Video video;

  const VideoDetailScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late Video _video = widget.video;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteVideo,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildVideoDetail(),
    );
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditVideoScreen(video: _video)),
    ).then((result) {
      if (result == true) {
        // Nếu cập nhật thành công, cần tải lại thông tin video
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin video')),
        );
        // Trong thực tế, cần gọi API để lấy dữ liệu mới nhất
        setState(() {
          // Reload video data
        });
      }
    });
  }

  Widget _buildVideoDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoPreview(),
          const SizedBox(height: 24),
          _buildVideoInfo(),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            image:
                _video.avatar != null && _video.avatar!.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(appImageCorrectUrl(_video.avatar!)),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              _video.avatar == null || _video.avatar!.isEmpty
                  ? const Center(
                    child: Icon(
                      Icons.video_library,
                      size: 60,
                      color: Colors.grey,
                    ),
                  )
                  : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Play button overlay
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
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
        const SizedBox(height: 16),
        // Video name
        Text(
          _video.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin video',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            _buildInfoRow(Icons.link, 'Đường dẫn', _video.video),
            _buildInfoRow(Icons.category, 'Loại', _video.type),
            if (_video.createdAt != null)
              _buildInfoRow(
                Icons.calendar_today,
                'Ngày tạo',
                _video.createdAt!,
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openVideoLink,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mở video'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoLink() {
    launchUrl(Uri.parse(_video.video));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label:', style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVideo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa video'),
            content: const Text('Bạn có chắc chắn muốn xóa video này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: _deleteVideo,
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteVideo() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Navigator.pop(context); // Đóng dialog xác nhận

       
      final response = await appDioClient.post(
        '/video/delete',
        data: {'id': _video.id},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa video thành công')),
        );

        // Quay lại màn hình danh sách
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể xóa video')));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi khi xóa video: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }
}
