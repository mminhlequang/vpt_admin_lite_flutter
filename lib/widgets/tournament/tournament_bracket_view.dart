import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../models/tournament.dart';

class TournamentBracketView extends StatelessWidget {
  final Tournament tournament;
  final Function(Match) onMatchTap;

  const TournamentBracketView({
    super.key,
    required this.tournament,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              // Đảm bảo chiều rộng đủ cho tất cả các vòng
              width: _calculateBracketWidth(constraints.maxWidth),
              // Đảm bảo chiều cao đủ cho tất cả các trận đấu
              height: _calculateBracketHeight(),
              child: CustomPaint(
                painter: BracketPainter(
                  tournament: tournament,
                  rounds: _organizeMatchesByRound(),
                ),
                child: _buildBracketContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateBracketWidth(double screenWidth) {
    // Mỗi vòng cần một khoảng không gian cố định
    final roundCount = _calculateRoundCount();
    // Chiều rộng của mỗi vòng là 180px + khoảng cách 40px
    return math.max(roundCount * 220.0, screenWidth);
  }

  double _calculateBracketHeight() {
    // Tính toán số trận đấu ở vòng đầu tiên
    final firstRoundMatchCount = _calculateFirstRoundMatchCount();
    // Mỗi trận đấu chiếm 80px chiều cao + khoảng cách 40px
    return math.max(firstRoundMatchCount * 120.0, 400.0);
  }

  int _calculateRoundCount() {
    // Số vòng đấu = log2(số đội tối đa)
    final teamCount = tournament.teams.length;
    if (teamCount <= 1) return 1;
    return math.max(log2(teamCount.toDouble()).ceil(), 1);
  }

  int _calculateFirstRoundMatchCount() {
    // Số trận ở vòng đầu tiên
    final teamCount = tournament.teams.length;
    // Số đội tối đa cho giải đấu này
    final maxTeams = math.pow(2, _calculateRoundCount()).toInt();
    // Số đội bye (được lên thẳng vòng sau)
    final byeCount = maxTeams - teamCount;
    // Số trận đấu ở vòng đầu tiên = (tổng số đội - số đội bye) / 2
    return math.max((teamCount - byeCount) ~/ 2, 1);
  }

  List<List<Match>> _organizeMatchesByRound() {
    final teamCount = tournament.teams.length;
    if (teamCount == 0) return [];

    // Tính toán số vòng đấu
    final roundCount = _calculateRoundCount();

    // Tính số đội tối đa cho giải đấu (lũy thừa của 2)
    final maxTeams = math.pow(2, roundCount).toInt();

    // Xây dựng bảng phân nhánh
    final List<List<Match>> rounds = [];

    // Danh sách các đội còn tham gia ở mỗi vòng
    List<Team> remainingTeams = List.from(tournament.teams);

    // Điều chỉnh số lượng đội để tạo các cặp đấu vòng đầu tiên
    while (remainingTeams.length < maxTeams) {
      remainingTeams.add(
        Team(
          id: 'placeholder_team_${remainingTeams.length}',
          name: 'TBD',
          players: [],
        ),
      );
    }

    // Xáo trộn đội theo hạt giống để tạo cặp đấu hợp lý
    remainingTeams = _seedTeams(remainingTeams);

    // Xây dựng vòng đầu tiên
    final firstRoundMatches = <Match>[];
    for (int i = 0; i < remainingTeams.length; i += 2) {
      final team1 = remainingTeams[i];
      final team2 = remainingTeams[i + 1];

      // Tìm trận đấu thực tế giữa hai đội này nếu có
      Match? actualMatch = _findMatchBetweenTeams(team1, team2);

      if (actualMatch != null) {
        // Nếu đã có trận đấu thực tế
        firstRoundMatches.add(actualMatch);
      } else {
        // Nếu chưa có trận đấu thực tế, tạo trận placeholder
        firstRoundMatches.add(
          Match(
            id: 'placeholder_0_${i ~/ 2}',
            team1: team1,
            team2: team2,
            status: MatchStatus.scheduled,
          ),
        );
      }
    }
    rounds.add(firstRoundMatches);

    // Xây dựng các vòng tiếp theo
    for (int r = 1; r < roundCount; r++) {
      final previousRound = rounds[r - 1];
      final currentRoundMatches = <Match>[];

      for (int i = 0; i < previousRound.length; i += 2) {
        if (i + 1 >= previousRound.length) {
          // Trường hợp đặc biệt: số lẻ trận đấu ở vòng trước
          continue;
        }

        final match1 = previousRound[i];
        final match2 = previousRound[i + 1];

        // Xác định đội tiến vào vòng tiếp theo
        Team? team1 =
            match1.winner ??
            (match1.status == MatchStatus.completed ? null : match1.team1);
        Team? team2 =
            match2.winner ??
            (match2.status == MatchStatus.completed ? null : match2.team1);

        if (team1 == null || team1.name == 'TBD') {
          team1 = Team(
            id: 'winner_of_' + match1.id,
            name: 'Đội thắng ' + _getMatchDisplayName(match1),
            players: [],
          );
        }

        if (team2 == null || team2.name == 'TBD') {
          team2 = Team(
            id: 'winner_of_' + match2.id,
            name: 'Đội thắng ' + _getMatchDisplayName(match2),
            players: [],
          );
        }

        // Tìm trận đấu thực tế giữa hai đội này nếu có
        Match? actualMatch = _findMatchBetweenTeams(team1, team2);

        if (actualMatch != null) {
          // Nếu đã có trận đấu thực tế
          currentRoundMatches.add(actualMatch);
        } else {
          // Nếu chưa có trận đấu thực tế, tạo trận placeholder
          currentRoundMatches.add(
            Match(
              id: 'placeholder_${r}_${i ~/ 2}',
              team1: team1,
              team2: team2,
              status: MatchStatus.scheduled,
            ),
          );
        }
      }
      rounds.add(currentRoundMatches);
    }

    return rounds;
  }

  // Tìm trận đấu thực tế giữa hai đội
  Match? _findMatchBetweenTeams(Team team1, Team team2) {
    if (team1.id.startsWith('placeholder') ||
        team2.id.startsWith('placeholder') ||
        team1.id.startsWith('winner_of') ||
        team2.id.startsWith('winner_of')) {
      return null;
    }

    for (var match in tournament.matches) {
      if ((match.team1.id == team1.id && match.team2.id == team2.id) ||
          (match.team1.id == team2.id && match.team2.id == team1.id)) {
        return match;
      }
    }
    return null;
  }

  // Lấy tên hiển thị cho trận đấu
  String _getMatchDisplayName(Match match) {
    if (match.id.startsWith('match_')) {
      final parts = match.id.split('_');
      if (parts.length > 1) {
        return 'Trận ${parts.last}';
      }
    } else if (match.id.startsWith('placeholder_')) {
      final parts = match.id.split('_');
      if (parts.length > 2) {
        return 'Trận ${parts[2]}';
      }
    }
    return match.id;
  }

  // Xáo trộn đội theo hạt giống để tạo cặp đấu hợp lý
  List<Team> _seedTeams(List<Team> teams) {
    final int n = teams.length;

    // Tách đội thực và đội placeholder
    final List<Team> realTeams = List.from(tournament.teams);
    final List<Team> placeholderTeams = [];

    for (int i = 0; i < teams.length; i++) {
      if (i >= realTeams.length) {
        placeholderTeams.add(teams[i]);
      }
    }

    // Tạo mảng kết quả
    final List<Team> result = List<Team>.filled(n, realTeams[0]);

    try {
      // Phân phối các đội thực theo thứ tự hạt giống
      for (int i = 0; i < realTeams.length && i < n; i++) {
        int pos = 0;
        if (i == 0) {
          pos = 0; // Hạt giống 1 ở vị trí đầu tiên
        } else if (i == 1 && n > 1) {
          pos = n - 1; // Hạt giống 2 ở vị trí cuối cùng
        } else if (n > 3) {
          // Xác định vị trí dựa trên thuật toán phân phối hạt giống
          if (i < 4) {
            // Hạt giống 3-4
            pos = (i == 2) ? (n ~/ 2) : (n ~/ 2 - 1);
          } else {
            // Các hạt giống còn lại được phân phối đều
            int section = i ~/ 4;
            int posInSection = i % 4;
            int sectionSize = n ~/ 4;
            pos = section * sectionSize + posInSection;
          }
        } else {
          // Nếu số đội ít, sắp xếp tuần tự
          pos = i;
        }

        // Đảm bảo vị trí hợp lệ
        if (pos < 0) pos = 0;
        if (pos >= n) pos = n - 1;

        // Kiểm tra xem vị trí đã được sử dụng chưa
        while (result[pos] != realTeams[0] && pos < n - 1) {
          pos++;
        }
        if (result[pos] == realTeams[0]) {
          result[pos] = realTeams[i];
        } else {
          // Tìm vị trí trống đầu tiên
          for (int j = 0; j < n; j++) {
            if (result[j] == realTeams[0]) {
              result[j] = realTeams[i];
              break;
            }
          }
        }
      }

      // Điền các đội placeholder vào các vị trí còn trống
      int placeholderIndex = 0;
      for (int i = 0; i < n; i++) {
        if (result[i] == realTeams[0]) {
          if (placeholderIndex < placeholderTeams.length) {
            result[i] = placeholderTeams[placeholderIndex++];
          } else {
            // Tạo một đội placeholder mới nếu cần
            result[i] = Team(
              id: 'placeholder_team_extra_${i}',
              name: 'TBD',
              players: [],
            );
          }
        }
      }

      return result;
    } catch (e) {
      print('Lỗi trong _seedTeams: $e');
      // Trả về danh sách ban đầu trong trường hợp có lỗi
      return teams;
    }
  }

  Widget _buildBracketContent() {
    final rounds = _organizeMatchesByRound();

    return Stack(
      children: [
        // Xây dựng các tiêu đề vòng đấu
        for (int roundIndex = 0; roundIndex < rounds.length; roundIndex++)
          _buildRoundHeader(roundIndex, rounds.length),

        // Xây dựng các trận đấu cho mỗi vòng
        for (int roundIndex = 0; roundIndex < rounds.length; roundIndex++)
          _buildRoundMatches(rounds[roundIndex], roundIndex),
      ],
    );
  }

  // Xây dựng tiêu đề cho mỗi vòng đấu
  Widget _buildRoundHeader(int roundIndex, int totalRounds) {
    String roundName;

    if (roundIndex == totalRounds - 1) {
      roundName = 'Chung kết';
    } else if (roundIndex == totalRounds - 2) {
      roundName = 'Bán kết';
    } else if (roundIndex == totalRounds - 3) {
      roundName = 'Tứ kết';
    } else {
      roundName = 'Vòng ${roundIndex + 1}';
    }

    return Positioned(
      left: roundIndex * 220.0,
      top: 0,
      width: 180.0,
      height: 30.0,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          roundName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundMatches(List<Match> matches, int roundIndex) {
    return Positioned(
      left: roundIndex * 220.0, // Mỗi vòng cách nhau 220px
      top: 40, // Để chỗ cho tiêu đề vòng đấu
      bottom: 0,
      width: 180.0, // Chiều rộng của mỗi khối trận đấu
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < matches.length; i++)
            _buildMatchTile(matches[i], roundIndex, i),
        ],
      ),
    );
  }

  Widget _buildMatchTile(Match match, int roundIndex, int matchIndex) {
    final bool isPlaceholder = match.id.startsWith('placeholder');
    final bool hasValidTeams =
        !isPlaceholder &&
        !match.team1.id.startsWith('winner_of') &&
        !match.team2.id.startsWith('winner_of') &&
        match.team1.name != 'TBD' &&
        match.team2.name != 'TBD';

    return GestureDetector(
      onTap: hasValidTeams ? () => onMatchTap(match) : null,
      child: Container(
        width: 180.0,
        height: 80.0,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPlaceholder ? Colors.grey[400]! : Colors.grey[700]!,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
          color: isPlaceholder ? Colors.grey[800] : Colors.grey[900],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamRow(
              match.team1.name,
              match.score1 ?? 0,
              isWinner: match.winner?.id == match.team1.id,
              isPlaceholder:
                  isPlaceholder ||
                  match.team1.name == 'TBD' ||
                  match.team1.id.startsWith('winner_of'),
              matchTime: match.scheduledTime,
              court: match.courtNumber,
            ),
            Container(height: 1.0, color: Colors.grey[700]),
            _buildTeamRow(
              match.team2.name,
              match.score2 ?? 0,
              isWinner: match.winner?.id == match.team2.id,
              isPlaceholder:
                  isPlaceholder ||
                  match.team2.name == 'TBD' ||
                  match.team2.id.startsWith('winner_of'),
              matchTime: null, // Chỉ hiển thị thời gian ở dòng đầu tiên
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String teamName,
    int score, {
    bool isWinner = false,
    bool isPlaceholder = false,
    DateTime? matchTime,
    String? court,
  }) {
    final isSpecialTeam = teamName.contains('Đội thắng');

    return Container(
      height: 39.0,
      decoration: BoxDecoration(
        color:
            isWinner
                ? Colors.green[800]
                : isPlaceholder
                ? Colors.grey[800]
                : Colors.grey[800],
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Row(
        children: [
          // Số thứ tự/hạt giống hoặc thời gian
          Container(
            width: 30.0,
            height: double.infinity,
            alignment: Alignment.center,
            child:
                matchTime != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(matchTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        if (court != null)
                          Text(
                            court,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    )
                    : Text(
                      isPlaceholder ? '-' : '•',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
          // Tên đội
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                isSpecialTeam
                    ? teamName
                    : teamName == 'TBD'
                    ? 'Chưa xác định'
                    : teamName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSpecialTeam ? 10 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Điểm số
          Container(
            width: 30.0,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isWinner
                      ? Colors.green[700]
                      : isPlaceholder
                      ? Colors.grey[700]
                      : Colors.grey[700],
            ),
            child: Text(
              isPlaceholder ? '-' : score.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm tính toán logarithm cơ số 2
  double log2(double x) => math.log(x) / math.ln2;
}

class BracketPainter extends CustomPainter {
  final Tournament tournament;
  final List<List<Match>> rounds;

  BracketPainter({required this.tournament, required this.rounds});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey[600]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Vẽ các đường kết nối giữa các trận đấu
    for (int roundIndex = 0; roundIndex < rounds.length - 1; roundIndex++) {
      final matchesInCurrentRound = rounds[roundIndex].length;
      final matchesInNextRound = rounds[roundIndex + 1].length;

      // Vị trí x của hai vòng đấu
      final currentRoundX = roundIndex * 220.0 + 180.0;
      final nextRoundX = (roundIndex + 1) * 220.0;

      // Khoảng cách giữa các trận đấu trong cùng vòng
      final currentRoundSpacing =
          (size.height - 40) / matchesInCurrentRound; // Trừ 40px cho tiêu đề
      final nextRoundSpacing = (size.height - 40) / matchesInNextRound;

      // Vẽ đường kết nối từ mỗi cặp trận đấu ở vòng hiện tại đến trận đấu ở vòng tiếp theo
      for (int i = 0; i < matchesInCurrentRound; i += 2) {
        if (i + 1 < matchesInCurrentRound) {
          // Vị trí y của hai trận đấu ở vòng hiện tại
          final match1Y =
              40 + i * currentRoundSpacing + currentRoundSpacing / 2;
          final match2Y =
              40 + (i + 1) * currentRoundSpacing + currentRoundSpacing / 2;

          // Vị trí y của trận đấu ở vòng tiếp theo
          final nextMatchY =
              40 + (i ~/ 2) * nextRoundSpacing + nextRoundSpacing / 2;

          // Vẽ đường ngang từ trận đấu 1
          canvas.drawLine(
            Offset(currentRoundX, match1Y),
            Offset(currentRoundX + 20, match1Y),
            paint,
          );

          // Vẽ đường ngang từ trận đấu 2
          canvas.drawLine(
            Offset(currentRoundX, match2Y),
            Offset(currentRoundX + 20, match2Y),
            paint,
          );

          // Vẽ đường dọc kết nối hai đường ngang
          canvas.drawLine(
            Offset(currentRoundX + 20, match1Y),
            Offset(currentRoundX + 20, match2Y),
            paint,
          );

          // Vẽ đường ngang đến trận đấu ở vòng tiếp theo
          canvas.drawLine(
            Offset(currentRoundX + 20, (match1Y + match2Y) / 2),
            Offset(nextRoundX, nextMatchY),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
