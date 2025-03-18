import 'package:flutter/material.dart';
import '../../models/player.dart';

class PlayerListItem extends StatelessWidget {
  final Player player;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTogglePaid;
  final bool showDetailedInfo;

  const PlayerListItem({
    Key? key,
    required this.player,
    this.onApprove,
    this.onReject,
    this.onTogglePaid,
    this.showDetailedInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatarCircle(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (player.email != null)
                        Text(
                          player.email!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 4),
                      if (player.phone != null)
                        Text(
                          player.phone!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      player.gender == 'male' ? Icons.male : Icons.female,
                      color:
                          player.gender == 'male'
                              ? Colors.blue
                              : Colors.pinkAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.gender == 'male' ? 'Nam' : 'Nữ',
                      style: TextStyle(
                        color:
                            player.gender == 'male'
                                ? Colors.blue
                                : Colors.pinkAccent,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.payments,
                      color:
                          player.hasPaid ? Colors.green[700] : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.hasPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                      style: TextStyle(
                        color:
                            player.hasPaid
                                ? Colors.green[700]
                                : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Hiển thị thông tin chi tiết nếu được yêu cầu
            if (showDetailedInfo) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildPlayerDetailedInfo(),
            ],

            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    if (player.avatar != null) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(player.avatar!),
        backgroundColor: Colors.grey[200],
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor:
          player.gender == 'male' ? Colors.blue[100] : Colors.pink[100],
      child: Text(
        player.name.isNotEmpty
            ? player.name.substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: player.gender == 'male' ? Colors.blue[800] : Colors.pink[800],
        ),
      ),
    );
  }

  Widget _buildPlayerDetailedInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiết',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (player.height != null)
              _buildInfoItem(Icons.height, 'Chiều cao: ${player.height} cm'),
            if (player.weight != null)
              _buildInfoItem(
                Icons.monitor_weight,
                'Cân nặng: ${player.weight} kg',
              ),
            if (player.paddle != null)
              _buildInfoItem(Icons.sports_tennis, 'Vợt: ${player.paddle}'),
            if (player.plays != null)
              _buildInfoItem(Icons.sports, 'Chơi: ${player.plays}'),
            if (player.back_hand != null)
              _buildInfoItem(Icons.back_hand, 'Thuận tay: ${player.back_hand}'),
            if (player.birth_date != null)
              _buildInfoItem(Icons.cake, 'Ngày sinh: ${player.birth_date}'),
            if (player.age != null)
              _buildInfoItem(Icons.person, 'Tuổi: ${player.age}'),
            if (player.coach != null)
              _buildInfoItem(Icons.sports, 'HLV: ${player.coach}'),
          ],
        ),

        const SizedBox(height: 12),

        // Thành tích
        Row(
          children: [
            _buildStatBox(
              'Thắng',
              player.total_win.toString(),
              Colors.green[100]!,
              Colors.green[800]!,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              'Thua',
              player.total_lose.toString(),
              Colors.red[100]!,
              Colors.red[800]!,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              'Thắng đôi',
              player.total_win_doubles.toString(),
              Colors.blue[100]!,
              Colors.blue[800]!,
            ),
            const SizedBox(width: 8),
            _buildStatBox(
              'Thua đôi',
              player.total_lose_doubles.toString(),
              Colors.orange[100]!,
              Colors.orange[800]!,
            ),
          ],
        ),

        // Liên kết mạng xã hội
        if (_hasSocialLinks()) ...[
          const SizedBox(height: 16),
          const Text(
            'Mạng xã hội',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSocialLinks(),
        ],
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(label, style: TextStyle(color: textColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  bool _hasSocialLinks() {
    return player.link_facebook != null ||
        player.link_twitter != null ||
        player.link_instagram != null ||
        player.link_youtube != null;
  }

  Widget _buildSocialLinks() {
    return Row(
      children: [
        if (player.link_facebook != null)
          IconButton(
            icon: const Icon(Icons.facebook, color: Colors.blue),
            onPressed: () {},
          ),
        if (player.link_twitter != null)
          IconButton(
            icon: const Icon(Icons.alternate_email, color: Colors.lightBlue),
            onPressed: () {},
          ),
        if (player.link_instagram != null)
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.purple),
            onPressed: () {},
          ),
        if (player.link_youtube != null)
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.red),
            onPressed: () {},
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    String text;

    switch (player.status) {
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

  Widget _buildActionButtons() {
    // Hiển thị các nút hành động tùy theo trạng thái
    if (player.status == RegistrationStatus.pending) {
      // Nút duyệt/từ chối cho trạng thái chờ duyệt
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check),
            label: const Text('Duyệt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else if (player.status == RegistrationStatus.approved) {
      // Nút cập nhật trạng thái thanh toán
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: onTogglePaid,
            icon: Icon(player.hasPaid ? Icons.money_off : Icons.attach_money),
            label: Text(
              player.hasPaid
                  ? 'Đánh dấu chưa trả tiền'
                  : 'Đánh dấu đã trả tiền',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: player.hasPaid ? Colors.orange : Colors.green,
            ),
          ),
        ],
      );
    }

    // Trạng thái từ chối - chỉ hiện nút gọi lại
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.call),
          label: const Text('Gọi điện'),
        ),
      ],
    );
  }
}
