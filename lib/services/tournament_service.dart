import 'dart:math';
import '../models/tournament.dart';
import '../models/player.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class TournamentService {
  final APIService _apiService = APIService();

  // Lấy danh sách giải đấu
  Future<List<Tournament>> getTournaments({
    int page = 1,
    int pageSize = ApiConstants.defaultPageSize,
    String? searchQuery,
    TournamentStatus? status,
  }) async {
    final queryParameters = {
      'page': page,
      'pageSize': pageSize,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      if (status != null) 'status': status.toString().split('.').last,
    };

    final response = await _apiService.get(
      ApiConstants.tournaments,
      queryParameters: queryParameters,
    );

    final List<dynamic> data = response['data'];
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  // Lấy chi tiết giải đấu
  Future<Tournament> getTournamentById(String id) async {
    final response = await _apiService.get('${ApiConstants.tournaments}/$id');
    return Tournament.fromJson(response['data']);
  }

  // Tạo giải đấu mới
  Future<Tournament> createTournament(Tournament tournament) async {
    final response = await _apiService.post(
      ApiConstants.tournaments,
      data: tournament.toJson(),
    );
    return Tournament.fromJson(response['data']);
  }

  // Cập nhật thông tin giải đấu
  Future<Tournament> updateTournament(Tournament tournament) async {
    final response = await _apiService.put(
      '${ApiConstants.tournaments}/${tournament.id}',
      data: tournament.toJson(),
    );
    return Tournament.fromJson(response['data']);
  }

  // Xóa giải đấu
  Future<bool> deleteTournament(String id) async {
    final response = await _apiService.delete(
      '${ApiConstants.tournaments}/$id',
    );
    return response['success'] == true;
  }

  // Tạo cặp đấu ngẫu nhiên
  List<Match> generateRandomMatches(Tournament tournament, List<Team> teams) {
    // Đảm bảo số lượng đội phù hợp
    if (teams.length < 2) {
      throw Exception('Cần ít nhất 2 đội để tạo cặp đấu');
    }

    // Xáo trộn danh sách đội
    final random = Random();
    final shuffledTeams = List<Team>.from(teams);
    for (int i = shuffledTeams.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      Team temp = shuffledTeams[i];
      shuffledTeams[i] = shuffledTeams[j];
      shuffledTeams[j] = temp;
    }

    // Tạo cặp đấu
    final matches = <Match>[];
    for (int i = 0; i < shuffledTeams.length - 1; i += 2) {
      if (i + 1 < shuffledTeams.length) {
        matches.add(
          Match(
            id: 'match_${tournament.id}_${matches.length + 1}',
            team1: shuffledTeams[i],
            team2: shuffledTeams[i + 1],
            status: MatchStatus.scheduled,
          ),
        );
      }
    }

    return matches;
  }

  // Tạo đội từ danh sách người chơi
  List<Team> createTeamsFromPlayers(
    List<Player> players,
    TournamentType type,
    int numberOfTeams,
  ) {
    if (players.isEmpty) {
      throw Exception('Danh sách người chơi không được để trống');
    }

    // Số người chơi trong một đội
    final int playersPerTeam = type == TournamentType.singles ? 1 : 2;

    // Đảm bảo có đủ người chơi
    if (players.length < numberOfTeams * playersPerTeam) {
      throw Exception(
        'Không đủ người chơi. Cần ${numberOfTeams * playersPerTeam} người chơi.',
      );
    }

    // Xáo trộn danh sách người chơi
    final random = Random();
    final shuffledPlayers = List<Player>.from(players);
    for (int i = shuffledPlayers.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      Player temp = shuffledPlayers[i];
      shuffledPlayers[i] = shuffledPlayers[j];
      shuffledPlayers[j] = temp;
    }

    // Tạo các đội
    final teams = <Team>[];
    for (int i = 0; i < numberOfTeams; i++) {
      final teamPlayers = <Player>[];
      for (int j = 0; j < playersPerTeam; j++) {
        if (i * playersPerTeam + j < shuffledPlayers.length) {
          teamPlayers.add(shuffledPlayers[i * playersPerTeam + j]);
        }
      }

      if (teamPlayers.length == playersPerTeam) {
        teams.add(
          Team(
            id: 'team_$i',
            name: _generateTeamName(teamPlayers),
            players: teamPlayers,
          ),
        );
      }
    }

    return teams;
  }

  // Tạo tên đội từ tên các thành viên
  String _generateTeamName(List<Player> players) {
    if (players.isEmpty) return 'Team';
    if (players.length == 1) return players[0].name;

    return players.map((player) => player.name.split(' ').last).join(' & ');
  }

  // Cập nhật kết quả trận đấu
  Future<Match> updateMatchResult(
    String tournamentId,
    String matchId,
    int score1,
    int score2,
  ) async {
    final data = {
      'score1': score1,
      'score2': score2,
      'status': MatchStatus.completed.toString().split('.').last,
    };

    final response = await _apiService.put(
      '${ApiConstants.tournaments}/$tournamentId/matches/$matchId',
      data: data,
    );

    return Match.fromJson(response['data']);
  }
}
