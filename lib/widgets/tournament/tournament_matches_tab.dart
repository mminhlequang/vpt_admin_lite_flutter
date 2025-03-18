import 'package:flutter/material.dart';
import '../../../models/tournament.dart';
import '../../../utils/constants.dart';
import 'tournament_bracket_view.dart';

class TournamentMatchesTab extends StatefulWidget {
  final Tournament tournament;
  final Function() onUpdateResults;
  final Function() onEditSchedule;

  const TournamentMatchesTab({
    super.key,
    required this.tournament,
    required this.onUpdateResults,
    required this.onEditSchedule,
  });

  @override
  State<TournamentMatchesTab> createState() => _TournamentMatchesTabState();
}

class _TournamentMatchesTabState extends State<TournamentMatchesTab> {
  bool _showBracketView = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh điều khiển chế độ xem
        Container(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút chuyển đổi chế độ xem
              ToggleButtons(
                isSelected: [_showBracketView, !_showBracketView],
                onPressed: (index) {
                  setState(() {
                    _showBracketView = index == 0;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Cây giải đấu'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Danh sách'),
                  ),
                ],
              ),
              // Nút chỉnh sửa lịch thi đấu
              if (widget.tournament.status == TournamentStatus.preparing ||
                  widget.tournament.status == TournamentStatus.ongoing)
                TextButton.icon(
                  onPressed: widget.onEditSchedule,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Chỉnh sửa lịch'),
                ),
            ],
          ),
        ),
        // Phần nội dung chính
        Expanded(
          child: _showBracketView ? _buildBracketView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildBracketView() {
    return TournamentBracketView(
      tournament: widget.tournament,
      onMatchTap: _showMatchDetailsDialog,
    );
  }

  Widget _buildListView() {
    final completedMatches =
        widget.tournament.matches
            .where((m) => m.status == MatchStatus.completed)
            .toList();
    final upcomingMatches =
        widget.tournament.matches
            .where((m) => m.status == MatchStatus.scheduled)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả trận đấu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (completedMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('Chưa có trận đấu nào hoàn thành')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedMatches.length,
              itemBuilder: (context, index) {
                final match = completedMatches[index];
                return GestureDetector(
                  onTap: () => _showMatchDetailsDialog(match),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.team1.name,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winner?.id == match.team1.id
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  '${match.score1} - ${match.score2}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  match.team2.name,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winner?.id == match.team2.id
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          const Text(
            'Trận đấu sắp tới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (upcomingMatches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text('Không có trận đấu sắp tới')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingMatches.length,
              itemBuilder: (context, index) {
                final match = upcomingMatches[index];
                return GestureDetector(
                  onTap: () => _showMatchDetailsDialog(match),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.team1.name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  match.team2.name,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          if (widget.tournament.status == TournamentStatus.ongoing)
            Center(
              child: ElevatedButton.icon(
                onPressed: widget.onUpdateResults,
                icon: const Icon(Icons.update),
                label: const Text('Cập nhật kết quả'),
              ),
            ),
        ],
      ),
    );
  }

  void _showMatchDetailsDialog(Match match) {
    // Hiển thị dialog chi tiết trận đấu khi người dùng nhấn vào một trận
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              match.status == MatchStatus.completed
                  ? 'Kết quả trận đấu'
                  : 'Thông tin trận đấu',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin đội và điểm số
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                match.team1.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      match.winner?.id == match.team1.id
                                          ? Colors.green
                                          : null,
                                ),
                              ),
                            ),
                            if (match.status == MatchStatus.completed)
                              Text(
                                '${match.score1} - ${match.score2}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            else
                              const Text(
                                'VS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                match.team2.name,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      match.winner?.id == match.team2.id
                                          ? Colors.green
                                          : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thông tin lịch thi đấu
                  if (match.scheduledTime != null) ...[
                    _buildInfoRow(
                      'Thời gian:',
                      '${match.scheduledTime!.day}/${match.scheduledTime!.month}/${match.scheduledTime!.year} ${match.scheduledTime!.hour}:${match.scheduledTime!.minute.toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildInfoRow(
                    'Địa điểm:',
                    match.courtNumber ?? 'Chưa xác định',
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    'Trạng thái:',
                    match.status == MatchStatus.completed
                        ? 'Đã hoàn thành'
                        : match.status == MatchStatus.ongoing
                        ? 'Đang diễn ra'
                        : match.status == MatchStatus.scheduled
                        ? 'Đã lên lịch'
                        : 'Đã hủy',
                  ),

                  // Thông tin đội tham gia
                  const SizedBox(height: 16),
                  const Text(
                    'Thành viên đội:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Thành viên đội 1
                  _buildTeamMembersInfo(match.team1),
                  const SizedBox(height: 8),

                  // Thành viên đội 2
                  _buildTeamMembersInfo(match.team2),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              if (match.status == MatchStatus.scheduled &&
                  (widget.tournament.status == TournamentStatus.preparing ||
                      widget.tournament.status == TournamentStatus.ongoing))
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEditSchedule();
                  },
                  child: const Text('Chỉnh sửa'),
                ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMembersInfo(Team team) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          ...team.players.map(
            (player) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        player.sex == 1 ? Colors.blue[100] : Colors.pink[100],
                    child: Text(
                      player.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color:
                            player.sex == 1
                                ? Colors.blue[800]
                                : Colors.pink[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (player.email != null)
                          Text(
                            player.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    player.sex == 1 ? Icons.male : Icons.female,
                    color: player.sex == 1 ? Colors.blue : Colors.pink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
