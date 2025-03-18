import 'package:flutter/material.dart';
import '../../../models/tournament.dart';
import '../../../utils/constants.dart';

class TournamentMatchesTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final completedMatches =
        tournament.matches
            .where((m) => m.status == MatchStatus.completed)
            .toList();
    final upcomingMatches =
        tournament.matches
            .where((m) => m.status == MatchStatus.scheduled)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch thi đấu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (tournament.status == TournamentStatus.preparing ||
                  tournament.status == TournamentStatus.ongoing)
                TextButton.icon(
                  onPressed: onEditSchedule,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Chỉnh sửa lịch'),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                return Card(
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
                return Card(
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
                );
              },
            ),
          const SizedBox(height: 24),
          if (tournament.status == TournamentStatus.ongoing)
            Center(
              child: ElevatedButton.icon(
                onPressed: onUpdateResults,
                icon: const Icon(Icons.update),
                label: const Text('Cập nhật kết quả'),
              ),
            ),
        ],
      ),
    );
  }
}
