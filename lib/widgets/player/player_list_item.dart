import 'package:flutter/material.dart';
import '../../models/player.dart';

class PlayerListItem extends StatelessWidget {
  final Player player;
  final bool showDetailedInfo;

  const PlayerListItem({
    Key? key,
    required this.player,
    this.showDetailedInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        player.name.isEmpty ? 'Chưa đặt tên' : player.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBasicInfoItem(
                        Icons.email,
                        'Email:',
                        player.email ?? 'Không rõ',
                      ),
                      const SizedBox(height: 4),
                      _buildBasicInfoItem(
                        Icons.phone,
                        'SĐT:',
                        player.phone ?? 'Không rõ',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
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
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      player.gender == 'male' ? 'Nam' : 'Nữ',
                      style: TextStyle(
                        color:
                            player.gender == 'male'
                                ? Colors.blue
                                : Colors.pinkAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 16,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hạng: ${player.rank > 0 ? player.rank.toString() : "Chưa xếp hạng"}',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
        backgroundImage: NetworkImage(
          player.avatar!.startsWith("http") == true
              ? player.avatar!
              : "https://familyworld.xyz/${player.avatar}",
        ),
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

  Widget _buildBasicInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerDetailedInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Thông tin cá nhân
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin cá nhân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildInfoItem(
                    Icons.height,
                    'Chiều cao',
                    player.height != null ? '${player.height} cm' : 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.monitor_weight,
                    'Cân nặng',
                    player.weight != null ? '${player.weight} kg' : 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.cake,
                    'Ngày sinh',
                    player.birth_date ?? 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.person,
                    'Tuổi',
                    player.age != null ? player.age.toString() : 'Không rõ',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Thông tin thi đấu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin thi đấu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildInfoItem(
                    Icons.sports_tennis,
                    'Vợt',
                    player.paddle ?? 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.sports,
                    'Chơi',
                    player.plays ?? 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.back_hand,
                    'Thuận tay',
                    player.back_hand ?? 'Không rõ',
                  ),
                  _buildInfoItem(
                    Icons.sports,
                    'HLV',
                    player.coach ?? 'Không rõ',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Thành tích
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thành tích',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
          ],
        ),

        // Liên kết mạng xã hội
        if (_hasSocialLinks()) ...[
          const SizedBox(height: 16),
          const Text(
            'Mạng xã hội',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSocialLinks(),
        ],
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        value == 'Không rõ'
                            ? Colors.grey[500]
                            : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Thêm nút gọi điện nếu có số điện thoại
        if (player.phone != null)
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            tooltip: 'Gọi điện',
            onPressed: () {
              // Xử lý sự kiện gọi điện
            },
          ),
        // Thêm nút email nếu có email
        if (player.email != null)
          IconButton(
            icon: const Icon(Icons.email, color: Colors.blue),
            tooltip: 'Gửi email',
            onPressed: () {
              // Xử lý sự kiện gửi email
            },
          ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Mở chi tiết người chơi
          },
          icon: const Icon(Icons.visibility),
          label: const Text('Xem chi tiết'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
