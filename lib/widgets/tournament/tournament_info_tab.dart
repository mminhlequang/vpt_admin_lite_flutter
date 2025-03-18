import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../models/tournament.dart';
import '../../../utils/constants.dart';

class TournamentInfoTab extends StatelessWidget {
  final Tournament tournament;
  final Function() onEdit;
  final Function() onExportSchedule;

  const TournamentInfoTab({
    super.key,
    required this.tournament,
    required this.onEdit,
    required this.onExportSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentHeader(),
          const SizedBox(height: 24),
          if (tournament.imageUrl != null) ...[
            _buildTournamentImage(),
            const SizedBox(height: 24),
          ],
          _buildTournamentDetails(),
          const SizedBox(height: 24),
          if (tournament.description != null) ...[
            _buildTournamentDescription(),
            const SizedBox(height: 24),
          ],
          _buildScheduleInfo(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildTournamentHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              tournament.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(tournament.status),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(tournament.startDate)} - ${_formatDate(tournament.endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentImage() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            tournament.imageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Không thể tải ảnh')),
                ),
          ),
        ],
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
              data: tournament.description!,
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
              tournament.type == TournamentType.singles ? 'Đấu đơn' : 'Đấu đôi',
            ),
            _buildInfoRow(
              'Giới hạn:',
              tournament.genderRestriction == GenderRestriction.male
                  ? 'Nam'
                  : tournament.genderRestriction == GenderRestriction.female
                  ? 'Nữ'
                  : 'Nam & Nữ',
            ),
            _buildInfoRow('Số đội:', '${tournament.numberOfTeams}'),
            _buildInfoRow(
              'Trận đấu đã hoàn thành:',
              '${tournament.matches.where((m) => m.status == MatchStatus.completed).length}/${tournament.matches.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleInfo() {
    // Thông tin về lịch trình sắp tới
    final upcomingMatches =
        tournament.matches
            .where((m) => m.status == MatchStatus.scheduled)
            .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch trình sắp tới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            if (upcomingMatches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Không có trận đấu sắp tới')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingMatches.length,
                itemBuilder: (context, index) {
                  final match = upcomingMatches[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.team1.name,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'VS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            match.team2.name,
                            textAlign: TextAlign.left,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${match.scheduledTime!.day}/${match.scheduledTime!.month} ${match.scheduledTime!.hour}:${match.scheduledTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              match.courtNumber ?? 'TBD',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
        color = Colors.orange;
        text = 'Chuẩn bị';
        break;
      case TournamentStatus.ongoing:
        color = Colors.green;
        text = 'Đang diễn ra';
        break;
      case TournamentStatus.completed:
        color = Colors.blue;
        text = 'Đã kết thúc';
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        text = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
