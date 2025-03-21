import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../models/tournament.dart';
import '../../models/match.dart';
import '../../models/team.dart';

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
    // Mỗi trận đấu chiếm 120px chiều cao và thêm khoảng trống giữa các trận đấu
    return math.max(firstRoundMatchCount * 180.0, 400.0);
  }

  int _calculateRoundCount() {
    // Số vòng đấu = log2(số đội tối đa)
    final teamCount = tournament.numberOfTeam ?? 0;
    if (teamCount <= 1) return 1;
    return math.max(log2(teamCount.toDouble()).ceil(), 1);
  }

  int _calculateFirstRoundMatchCount() {
    // Số trận ở vòng đầu tiên
    final teamCount = tournament.numberOfTeam ?? 0;
    // Số đội tối đa cho giải đấu này
    final maxTeams = math.pow(2, _calculateRoundCount()).toInt();
    // Số đội bye (được lên thẳng vòng sau)
    final byeCount = maxTeams - teamCount;
    // Số trận đấu ở vòng đầu tiên = (tổng số đội - số đội bye) / 2
    return math.max((teamCount - byeCount) ~/ 2, 1);
  }

  List<List<Match>> _organizeMatchesByRound() {
    // Lấy tất cả các trận đấu từ tất cả các vòng
    final allMatches = <Match>[];
    if (tournament.rounds != null) {
      for (final round in tournament.rounds!) {
        allMatches.addAll(round.matches);
      }
    }

    // Sử dụng numberOfTeam thay vì độ dài của danh sách teams
    final expectedTeamCount = tournament.numberOfTeam ?? 0;
    if (expectedTeamCount == 0) return [];

    // Tính toán số vòng đấu
    final roundCount = _calculateRoundCount();

    // Tính số đội tối đa cho giải đấu (lũy thừa của 2)
    final maxTeams = math.pow(2, roundCount).toInt();

    // Xây dựng bảng phân nhánh
    final List<List<Match>> rounds = [];

    // Tạo danh sách đội dự kiến
    List<Team> allTeams = [];

    // Thêm các đội đã đăng ký (nếu có)
    if (tournament.teams != null) {
      allTeams.addAll(tournament.teams!);
    }

    // Thêm các đội placeholder cho đủ số lượng dự kiến
    while (allTeams.length < expectedTeamCount) {
      allTeams.add(
        Team(
          id: 'placeholder_team_${allTeams.length}',
          name: 'TBD ${allTeams.length + 1}',
        ),
      );
    }

    // Thêm các đội placeholder cho đủ số lượng là lũy thừa của 2 (nếu cần)
    while (allTeams.length < maxTeams) {
      allTeams.add(
        Team(id: 'placeholder_team_${allTeams.length}', name: 'TBD'),
      );
    }

    // Xáo trộn đội theo hạt giống để tạo cặp đấu hợp lý
    allTeams = _seedTeams(allTeams);

    // Xây dựng vòng đầu tiên
    final firstRoundMatches = <Match>[];
    for (int i = 0; i < allTeams.length; i += 2) {
      final team1 = allTeams[i];
      final team2 = allTeams[i + 1];

      // Tìm trận đấu thực tế giữa hai đội này nếu có
      Match? actualMatch = _findMatchBetweenTeams(team1, team2, allMatches);

      if (actualMatch != null) {
        // Nếu đã có trận đấu thực tế
        firstRoundMatches.add(actualMatch);
      } else {
        // Nếu chưa có trận đấu thực tế, tạo trận placeholder
        final roundId =
            tournament.rounds != null && tournament.rounds!.isNotEmpty
                ? tournament.rounds!.first.id
                : 0;

        firstRoundMatches.add(
          Match(
            id: i ~/ 2, // Sử dụng số nguyên trực tiếp thay vì int.parse()
            roundId: roundId, // Vòng đầu tiên
            team1: team1,
            team2: team2,
            team1Id:
                team1.id.startsWith('placeholder')
                    ? null
                    : int.tryParse(team1.id),
            team2Id:
                team2.id.startsWith('placeholder')
                    ? null
                    : int.tryParse(team2.id),
            scheduledTime: DateTime.now(),
            matchStatus: MatchStatus.pending,
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
        Team? team1;
        if (match1.winnerId != null &&
            match1.team1 != null &&
            match1.team2 != null) {
          team1 =
              match1.winnerId == match1.team1Id ? match1.team1 : match1.team2;
        } else {
          team1 =
              match1.matchStatus == MatchStatus.completed ? null : match1.team1;
        }

        Team? team2;
        if (match2.winnerId != null &&
            match2.team1 != null &&
            match2.team2 != null) {
          team2 =
              match2.winnerId == match2.team1Id ? match2.team1 : match2.team2;
        } else {
          team2 =
              match2.matchStatus == MatchStatus.completed ? null : match2.team1;
        }

        if (team1 == null || team1.name == 'TBD') {
          team1 = Team(
            id: 'winner_of_${match1.id}',
            name: 'Đội thắng ' + _getMatchDisplayName(match1),
          );
        }

        if (team2 == null || team2.name == 'TBD') {
          team2 = Team(
            id: 'winner_of_${match2.id}',
            name: 'Đội thắng ' + _getMatchDisplayName(match2),
          );
        }

        // Tìm trận đấu thực tế giữa hai đội này nếu có
        Match? actualMatch = _findMatchBetweenTeams(team1, team2, allMatches);

        if (actualMatch != null) {
          // Nếu đã có trận đấu thực tế
          currentRoundMatches.add(actualMatch);
        } else {
          // Nếu chưa có trận đấu thực tế, tạo trận placeholder
          int roundId = 0;
          if (tournament.rounds != null && tournament.rounds!.isNotEmpty) {
            roundId =
                r < tournament.rounds!.length
                    ? tournament.rounds![r].id
                    : tournament.rounds!.last.id;
          }

          currentRoundMatches.add(
            Match(
              id:
                  1000 +
                  r * 100 +
                  i ~/ 2, // Tạo ID duy nhất không sử dụng ký tự đặc biệt
              roundId: roundId,
              team1: team1,
              team2: team2,
              team1Id:
                  team1.id.startsWith('winner_of') ||
                          team1.id.startsWith('placeholder')
                      ? null
                      : int.tryParse(team1.id),
              team2Id:
                  team2.id.startsWith('winner_of') ||
                          team2.id.startsWith('placeholder')
                      ? null
                      : int.tryParse(team2.id),
              scheduledTime: DateTime.now(),
              matchStatus: MatchStatus.pending,
            ),
          );
        }
      }
      rounds.add(currentRoundMatches);
    }

    return rounds;
  }

  // Tìm trận đấu thực tế giữa hai đội
  Match? _findMatchBetweenTeams(
    Team team1,
    Team team2,
    List<Match> allMatches,
  ) {
    if (team1.id.startsWith('placeholder') ||
        team2.id.startsWith('placeholder') ||
        team1.id.startsWith('winner_of') ||
        team2.id.startsWith('winner_of')) {
      return null;
    }

    for (var match in allMatches) {
      if ((match.team1Id.toString() == team1.id &&
              match.team2Id.toString() == team2.id) ||
          (match.team1Id.toString() == team2.id &&
              match.team2Id.toString() == team1.id)) {
        return match;
      }
    }
    return null;
  }

  // Lấy tên hiển thị cho trận đấu
  String _getMatchDisplayName(Match match) {
    return 'Trận ${match.id}';
  }

  // Xáo trộn đội theo hạt giống để tạo cặp đấu hợp lý
  List<Team> _seedTeams(List<Team> teams) {
    final int n = teams.length;

    // Tách đội thực và đội placeholder
    final List<Team> realTeams = [];
    final List<Team> placeholderTeams = [];

    // Chỉ lấy các team không phải placeholder
    for (var team in teams) {
      if (!team.id.startsWith('placeholder')) {
        realTeams.add(team);
      } else {
        placeholderTeams.add(team);
      }
    }

    // Tạo mảng kết quả
    if (realTeams.isEmpty) {
      // Nếu không có đội thực, trả về danh sách placeholder theo thứ tự
      return teams;
    }

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
            result[i] = Team(id: 'placeholder_team_extra_${i}', name: 'TBD');
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
    if (rounds.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có đủ dữ liệu để hiển thị cây giải đấu',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final totalRounds = rounds.length;

    return Stack(
      children: [
        // Hiển thị tiêu đề các vòng đấu
        for (int i = 0; i < totalRounds; i++) _buildRoundHeader(i, totalRounds),

        // Hiển thị các trận đấu trong từng vòng
        for (int i = 0; i < totalRounds; i++) _buildRoundMatches(rounds[i], i),
      ],
    );
  }

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
    // Tính toán chiều cao có sẵn cho các trận đấu
    final availableHeight =
        _calculateBracketHeight() - 40; // Trừ đi chiều cao của header

    return Positioned(
      left: roundIndex * 220.0, // Mỗi vòng cách nhau 220px
      top: 40, // Để chỗ cho tiêu đề vòng đấu
      bottom: 0,
      width: 180.0, // Chiều rộng của mỗi khối trận đấu
      child: SizedBox(
        height: availableHeight,
        child: Stack(
          children: [
            for (int i = 0; i < matches.length; i++)
              Positioned(
                top: i * (availableHeight / matches.length),
                left: 0,
                right: 0,
                child: _buildMatchTile(matches[i], roundIndex, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTile(Match match, int roundIndex, int matchIndex) {
    final isCompleted = match.matchStatus == MatchStatus.completed;
    final bool isPlaceholder =
        match.team1?.id.startsWith('placeholder') == true ||
        match.team2?.id.startsWith('placeholder') == true ||
        match.team1?.id.startsWith('winner_of') == true ||
        match.team2?.id.startsWith('winner_of') == true;

    return GestureDetector(
      onTap: isPlaceholder ? null : () => onMatchTap(match),
      child: Container(
        width: 180.0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isPlaceholder
                    ? Colors.grey[300]!
                    : isCompleted
                    ? Colors.green
                    : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color:
                  isPlaceholder
                      ? Colors.grey[200]
                      : isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : match.matchStatus == MatchStatus.ongoing
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${roundIndex + 1}.${matchIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isPlaceholder
                              ? Colors.grey[600]
                              : isCompleted
                              ? Colors.green
                              : Colors.grey[600],
                    ),
                  ),
                  if (!isPlaceholder && match.scheduledTime != null)
                    Text(
                      DateFormat('dd/MM HH:mm').format(match.scheduledTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.green : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildTeamRow(
                    match.team1?.name ?? 'TBD',
                    isWinner: isCompleted && match.winnerId == match.team1Id,
                    score: isCompleted ? match.team1Score : null,
                    isPlaceholder:
                        match.team1?.id.startsWith('placeholder') == true ||
                        match.team1?.id.startsWith('winner_of') == true,
                  ),
                  const Divider(height: 16),
                  _buildTeamRow(
                    match.team2?.name ?? 'TBD',
                    isWinner: isCompleted && match.winnerId == match.team2Id,
                    score: isCompleted ? match.team2Score : null,
                    isPlaceholder:
                        match.team2?.id.startsWith('placeholder') == true ||
                        match.team2?.id.startsWith('winner_of') == true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    String teamName, {
    bool isWinner = false,
    int? score,
    bool isPlaceholder = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color:
                  isPlaceholder
                      ? Colors.grey[500]
                      : isWinner
                      ? Colors.green
                      : null,
              fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (score != null)
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWinner ? Colors.green : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: isWinner ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// Lớp vẽ các đường kết nối giữa các trận đấu
class BracketPainter extends CustomPainter {
  final Tournament tournament;
  final List<List<Match>> rounds;

  BracketPainter({required this.tournament, required this.rounds});

  @override
  void paint(Canvas canvas, Size size) {
    if (rounds.length <= 1) return;

    final paint =
        Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    // Vẽ đường kết nối giữa các trận đấu
    for (int r = 1; r < rounds.length; r++) {
      final currentRound = rounds[r];
      final previousRound = rounds[r - 1];

      // Chiều cao khả dụng cho mỗi vòng (trừ đi phần header)
      final availableHeight = size.height - 40;

      // Chiều cao thực tế của một trận đấu (khoảng 80px)
      final matchHeight = 80.0;

      // Khoảng cách giữa các trận trong mỗi vòng
      final prevRoundSpacing = availableHeight / previousRound.length;
      final currentRoundSpacing = availableHeight / currentRound.length;

      for (int i = 0; i < currentRound.length; i++) {
        // Vị trí X của các cột
        final prevRoundX =
            (r - 1) * 220.0 +
            180.0; // X-coordinate của phần cuối trận đấu ở vòng trước
        final currentRoundX =
            r * 220.0; // X-coordinate của phần đầu trận đấu ở vòng hiện tại

        // Vị trí Y của trận đấu hiện tại (giữa trận đấu)
        final currentY = 40 + i * currentRoundSpacing + matchHeight / 2;

        // Tính toán các trận ở vòng trước kết nối đến trận hiện tại
        final prevIndex1 = i * 2;
        final prevIndex2 = i * 2 + 1;

        if (prevIndex1 < previousRound.length) {
          // Vị trí Y của trận đấu thứ nhất ở vòng trước
          final prevY1 = 40 + prevIndex1 * prevRoundSpacing + matchHeight / 2;

          // Vẽ đường kết nối từ trận trước đến trận hiện tại
          final path = Path();
          path.moveTo(
            prevRoundX,
            prevY1,
          ); // Bắt đầu từ điểm cuối của trận trước
          path.lineTo(prevRoundX + 20, prevY1); // Di chuyển ngang một đoạn
          path.lineTo(
            prevRoundX + 20,
            currentY,
          ); // Di chuyển dọc đến vị trí trận hiện tại
          path.lineTo(
            currentRoundX,
            currentY,
          ); // Di chuyển ngang đến trận hiện tại

          canvas.drawPath(path, paint);
        }

        if (prevIndex2 < previousRound.length) {
          // Vị trí Y của trận đấu thứ hai ở vòng trước
          final prevY2 = 40 + prevIndex2 * prevRoundSpacing + matchHeight / 2;

          // Vẽ đường kết nối từ trận trước đến trận hiện tại
          final path = Path();
          path.moveTo(
            prevRoundX,
            prevY2,
          ); // Bắt đầu từ điểm cuối của trận trước
          path.lineTo(prevRoundX + 20, prevY2); // Di chuyển ngang một đoạn
          path.lineTo(
            prevRoundX + 20,
            currentY,
          ); // Di chuyển dọc đến vị trí trận hiện tại
          path.lineTo(
            currentRoundX,
            currentY,
          ); // Di chuyển ngang đến trận hiện tại

          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Hàm tính log cơ số 2
double log2(double x) {
  return math.log(x) / math.log(2);
}
