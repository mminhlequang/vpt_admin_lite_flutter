import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:internal_core/widgets/widgets.dart';
import 'package:vpt_admin_lite_flutter/screens/tournaments/rounds_screen.dart';
import '../../../models/tournament.dart';
import '../../../utils/constants.dart';
import 'package:intl/intl.dart';

class TournamentInfoTab extends StatelessWidget {
  final Tournament tournament;
  final Function() onEdit;
  final Function() onExportSchedule;
  final VoidCallback fetchTournament;

  const TournamentInfoTab({
    super.key,
    required this.tournament,
    required this.onEdit,
    required this.onExportSchedule,
    required this.fetchTournament,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentHeader(),
          const SizedBox(height: 16),

          _buildTournamentDetails(),
          const SizedBox(height: 16),
          if (tournament.content != null) ...[
            _buildTournamentDescription(),
            const SizedBox(height: 16),
          ],
          _buildRoundsTab(context),
          const SizedBox(height: 16),
          _buildActions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTournamentHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (tournament.avatar != null) ...[
              WidgetAppImage(
                imageUrl: tournament.avatar,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                radius: 12,
              ),
              const SizedBox(height: 16),
            ],
            Column(
              children: [
                const SizedBox(width: 16.0),
                Text(
                  tournament.name ?? '',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(
                      '${tournament.startDate} - ${tournament.endDate}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                if (tournament.city != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16.0),
                      const SizedBox(width: 4.0),
                      Text(
                        tournament.city!,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.type_specimen,
                            size: 14.0,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 2.0),
                          Text(
                            tournament.category?.numberOfPlayer == 1
                                ? 'Đấu đơn'
                                : 'Đấu đôi',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (tournament.genderRestriction != null)
                      ..._buildGenderBadges(tournament.category?.sex ?? 2),
                    Spacer(),
                    _buildStatusBadge(tournament.status!),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mô tả giải đấu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Html(
              data: tournament.content!,
              style: {
                "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
                "h2": Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(bottom: 8),
                ),
                "h3": Style(
                  fontSize: FontSize(16),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(bottom: 8, top: 16),
                ),
                "p": Style(margin: Margins.only(bottom: 8, top: 8)),
                "ul": Style(margin: Margins.only(left: 16)),
                "ol": Style(margin: Margins.only(left: 16)),
                "li": Style(margin: Margins.only(bottom: 4)),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết giải đấu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            _buildInfoRow(
              'Loại giải đấu:',
              tournament.category?.numberOfPlayer == 1 ? 'Đấu đơn' : 'Đấu đôi',
            ),
            _buildInfoRow(
              'Giới hạn:',
              tournament.category?.sex == 1
                  ? 'Nam'
                  : tournament.category?.sex == 2
                  ? 'Nữ'
                  : 'Nam & Nữ',
            ),
            _buildInfoRow('Số đội:', '${tournament.numberOfTeam}'),
            // _buildInfoRow(
            //   'Trận đấu đã hoàn thành:',
            //   '${tournament.matches.where((m) => m.status == MatchStatus.completed).length}/${tournament.matches.length}',
            // ),
            if (tournament.category != null)
              _buildInfoRow('Danh mục:', tournament.category!.name),
            if (tournament.city != null)
              _buildInfoRow('Thành phố:', tournament.city!),
            if (tournament.surface != null)
              _buildInfoRow('Bề mặt sân:', tournament.surface!),
            if (tournament.prize != null)
              _buildInfoRow(
                'Giải thưởng:',
                '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(tournament.prize)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.access_time, size: 48, color: Colors.indigo),
                const SizedBox(height: 16),
                Text(
                  'Quản lý vòng đấu',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổ chức các vòng đấu, phân chia trận đấu và theo dõi tiến độ giải',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _navigateToRoundsScreen(context, tournament),
                  icon: const Icon(Icons.sports),
                  label: const Text('Quản lý vòng đấu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Lưu ý khi quản lý vòng đấu:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRoundsInfoList(),
      ],
    );
  }

  Widget _buildRoundsInfoList() {
    final tips = [
      'Thiết lập các vòng đấu khác nhau như vòng loại, tứ kết, bán kết và chung kết',
      'Phân chia và sắp xếp các trận đấu trong mỗi vòng',
      'Cập nhật kết quả và theo dõi tiến độ của các trận đấu',
      'Tạo trận đấu tự động hoặc thủ công từ các đội tham gia',
      'Tạo lịch trình cho các trận đấu với thời gian và địa điểm cụ thể',
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tips[index],
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToRoundsScreen(BuildContext context, Tournament tournament) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoundsScreen(
          tournament: tournament,
          fetchTournament: fetchTournament,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: onExportSchedule,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Xuất lịch'),
        ),
        if (tournament.status == TournamentStatus.preparing ||
            tournament.status == TournamentStatus.ongoing)
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    late Color color;
    late String text;

    switch (status) {
      case TournamentStatus.preparing:
        color = Colors.blue;
        text = 'Đang chuẩn bị';
        break;
      case TournamentStatus.ongoing:
        color = Colors.green;
        text = 'Đang diễn ra';
        break;
      case TournamentStatus.completed:
        color = Colors.purple;
        text = 'Đã kết thúc';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12.0)),
    );
  }

  //sex = 1: nam, 2: nữ, 3: nam/nữ
  List<Widget> _buildGenderBadges(int sex) {
    List<Widget> badges = [];

    List<String> genders = [];

    if (sex == 1) {
      genders = ['male'];
    } else if (sex == 2) {
      genders = ['female'];
    } else {
      genders = ['mixed'];
    }

    for (String gender in genders) {
      late Color color;
      late IconData icon;

      switch (gender.toLowerCase()) {
        case 'male':
          color = Colors.blue;
          icon = Icons.male;
          break;
        case 'female':
          color = Colors.pink;
          icon = Icons.female;
          break;
        case 'mixed':
        default:
          color = Colors.purple;
          icon = Icons.people;
          break;
      }

      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.0, color: color),
              const SizedBox(width: 2.0),
              Text(
                _getGenderText(gender),
                style: TextStyle(color: color, fontSize: 12.0),
              ),
            ],
          ),
        ),
      );
    }

    return badges;
  }

  String _getGenderText(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      case 'mixed':
      default:
        return 'Nam/Nữ';
    }
  }
}
