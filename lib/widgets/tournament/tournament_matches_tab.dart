import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vpt_admin_lite_flutter/screens/tournaments/rounds_screen.dart';
import '../../models/tournament.dart';
import '../../models/match.dart';
import '../../utils/constants.dart';
import 'tournament_bracket_view.dart';

class TournamentMatchesTab extends StatefulWidget {
  final Tournament tournament;
  final Function() onUpdateResults;
  final Function() onEditSchedule;
  final VoidCallback fetchTournament;

  const TournamentMatchesTab({
    super.key,
    required this.tournament,
    required this.onUpdateResults,
    required this.onEditSchedule,
    required this.fetchTournament,
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
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Cây giải đấu'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
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
                  label: const Text('Lịch'),
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
    // Lấy tất cả trận đấu từ tất cả vòng
    final allMatches = <TournamentMatch>[];
    if (widget.tournament.rounds != null) {
      for (final round in widget.tournament.rounds!) {
        allMatches.addAll(round.matches ?? []);
      }
    }

    // Phân loại các trận đấu
    final completedMatches =
        allMatches
            .where((m) => m.matchStatus == MatchStatus.completed)
            .toList();
    final upcomingMatches =
        allMatches
            .where((m) => m.matchStatus != MatchStatus.completed)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý vòng đấu',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tổ chức các vòng đấu, phân chia trận đấu và theo dõi tiến độ giải',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RoundsScreen(
                        tournament: widget.tournament,
                        fetchTournament: widget.fetchTournament,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.sports),
            label: const Text('Quản lý vòng đấu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
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
                                  match.team1?.name ?? 'TBD',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winner?.id == match.team1?.id
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
                                  '${match.team1Score ?? 0} - ${match.team2Score ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  match.team2?.name ?? 'TBD',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        match.winner?.id == match.team2?.id
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
                                match.scheduledTime ?? "",
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
                                match.stadium ?? 'TBD',
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
                                  match.team1?.name ?? 'TBD',
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
                                  match.team2?.name ?? 'TBD',
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
                                match.scheduledTime ?? "",
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
                                match.stadium ?? 'TBD',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (match.matchStatus == MatchStatus.ongoing)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Text(
                                'Đang diễn ra',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showMatchDetailsDialog(TournamentMatch match) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _getRoundName(match.round?.id ?? 0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.team1?.name ?? 'TBD',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              match.winner?.id == match.team1?.id
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                          match.matchStatus == MatchStatus.completed
                              ? Text(
                                '${match.team1Score ?? 0} - ${match.team2Score ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                              : const Text(
                                'VS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                    ),
                    Expanded(
                      child: Text(
                        match.team2?.name ?? 'TBD',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              match.winner?.id == match.team2?.id
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      match.scheduledTime ?? "",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      match.scheduledTime ?? "",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      match.stadium ?? 'Chưa có sân',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      match.matchStatus ?? MatchStatus.pending,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(
                        match.matchStatus ?? MatchStatus.pending,
                      ),
                    ),
                  ),
                  child: Text(
                    _getStatusText(match.matchStatus ?? MatchStatus.pending),
                    style: TextStyle(
                      color: _getStatusColor(
                        match.matchStatus ?? MatchStatus.pending,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
              if (match.matchStatus != MatchStatus.completed)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onUpdateResults();
                  },
                  child: const Text('Cập nhật kết quả'),
                ),
            ],
          ),
    );
  }

  String _getRoundName(int roundId) {
    if (widget.tournament.rounds == null) return 'Trận đấu';

    for (final round in widget.tournament.rounds!) {
      if (round.id == roundId) {
        return round.name ?? '';
      }
    }
    return 'Trận đấu';
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return Colors.grey;
      case MatchStatus.ongoing:
        return Colors.orange;
      case MatchStatus.completed:
        return Colors.green;
      case MatchStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return 'Chưa diễn ra';
      case MatchStatus.ongoing:
        return 'Đang diễn ra';
      case MatchStatus.completed:
        return 'Đã hoàn thành';
      case MatchStatus.cancelled:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
}
