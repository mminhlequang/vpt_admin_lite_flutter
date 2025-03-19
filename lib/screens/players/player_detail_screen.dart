import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../utils/constants.dart';
import 'edit_player_screen.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  late Player _player = widget.player;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết người chơi')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPlayerDetail(),
    );
  }

  Widget _buildPlayerDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPersonalInfo(),
          const SizedBox(height: 24),
          _buildStatusInfo(),
          const SizedBox(height: 24),
          _buildTournamentHistory(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor:
                _player.gender == 'male' ? Colors.blue[100] : Colors.pink[100],
            child: Text(
              _player.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color:
                    _player.gender == 'male'
                        ? Colors.blue[800]
                        : Colors.pink[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _player.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _player.gender == 'male' ? Icons.male : Icons.female,
                color: _player.gender == 'male' ? Colors.blue : Colors.pink,
              ),
              const SizedBox(width: 8),
              Text(
                _player.gender == 'male' ? 'Nam' : 'Nữ',
                style: TextStyle(
                  color: _player.gender == 'male' ? Colors.blue : Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            _buildInfoRow(
              Icons.email,
              'Email',
              _player.email ?? 'Chưa cập nhật',
            ),
            _buildInfoRow(
              Icons.phone,
              'Số điện thoại',
              _player.phone ?? 'Chưa cập nhật',
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày đăng ký',
              '${_player.registrationDate.day}/${_player.registrationDate.month}/${_player.registrationDate.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Row(
              children: [
                const Text('Tình trạng:'),
                const Spacer(),
                _buildStatusBadge(_player.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Thanh toán:'),
                const Spacer(),
                _buildPaymentBadge(_player.hasPaid),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentHistory() {
    // Giả lập danh sách giải đấu đã tham gia
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch sử tham gia giải đấu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            // Giả lập dữ liệu
            ListTile(
              title: const Text('Giải Pickleball Mùa Xuân 2023'),
              subtitle: const Text('15/03/2023 - 20/03/2023'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: const Text(
                  'Đã hoàn thành',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Giải Pickleball Mùa Hè 2023'),
              subtitle: const Text('01/07/2023 - 10/07/2023'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'Đang diễn ra',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // Xử lý gọi điện
          },
          icon: const Icon(Icons.phone),
          label: const Text('Gọi điện'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Xử lý gửi email
          },
          icon: const Icon(Icons.email),
          label: const Text('Gửi email'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            // Xử lý chỉnh sửa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPlayerScreen(player: _player),
              ),
            ).then((result) {
              if (result == true) {
                // Nếu cập nhật thành công, tải lại thông tin người chơi
                // Trong trường hợp thực tế, cần gọi API để lấy dữ liệu mới nhất
                setState(() {
                  // Reload player data
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật thông tin người chơi'),
                  ),
                );
              }
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Chỉnh sửa'),
        ),
      ],
    );
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RegistrationStatus status) {
    Color backgroundColor;
    String text;

    switch (status) {
      case RegistrationStatus.approved:
        backgroundColor = Colors.green;
        text = 'Đã duyệt';
        break;
      case RegistrationStatus.pending:
        backgroundColor = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case RegistrationStatus.rejected:
        backgroundColor = Colors.red;
        text = 'Từ chối';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(bool hasPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasPaid ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
