import 'player.dart';

class Tournament {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentType type; // Singles hoặc doubles
  final GenderRestriction genderRestriction; // Nam, nữ, hỗn hợp
  final int numberOfTeams;
  final List<Team> teams;
  final List<Match> matches;
  final TournamentStatus status;
  final String? imageUrl;
  final String? description;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.genderRestriction,
    required this.numberOfTeams,
    this.teams = const [],
    this.matches = const [],
    this.status = TournamentStatus.preparing,
    this.imageUrl,
    this.description,
  });

  // Tạo từ JSON
  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: TournamentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TournamentType.singles,
      ),
      genderRestriction: GenderRestriction.values.firstWhere(
        (e) => e.toString().split('.').last == json['genderRestriction'],
        orElse: () => GenderRestriction.mixed,
      ),
      numberOfTeams: json['numberOfTeams'],
      teams:
          (json['teams'] as List?)
              ?.map((team) => Team.fromJson(team))
              .toList() ??
          [],
      matches:
          (json['matches'] as List?)
              ?.map((match) => Match.fromJson(match))
              .toList() ??
          [],
      status: TournamentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TournamentStatus.preparing,
      ),
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'genderRestriction': genderRestriction.toString().split('.').last,
      'numberOfTeams': numberOfTeams,
      'teams': teams.map((team) => team.toJson()).toList(),
      'matches': matches.map((match) => match.toJson()).toList(),
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Tournament copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    TournamentType? type,
    GenderRestriction? genderRestriction,
    int? numberOfTeams,
    List<Team>? teams,
    List<Match>? matches,
    TournamentStatus? status,
    String? imageUrl,
    String? description,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      genderRestriction: genderRestriction ?? this.genderRestriction,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}

class Team {
  final String id;
  final String name;
  final List<Player> players;

  Team({required this.id, required this.name, required this.players});

  // Tạo từ JSON
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'].toString(),
      name: json['name'],
      players:
          (json['players'] as List?)
              ?.map((player) => Player.fromJson(player))
              .toList() ??
          [],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((player) => player.toJson()).toList(),
    };
  }
}

class Match {
  final String id;
  final Team team1;
  final Team team2;
  final int? score1;
  final int? score2;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final String? courtNumber;
  final Team? winner;

  Match({
    required this.id,
    required this.team1,
    required this.team2,
    this.score1,
    this.score2,
    this.status = MatchStatus.scheduled,
    this.scheduledTime,
    this.courtNumber,
    this.winner,
  });

  // Tạo từ JSON
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      team1: Team.fromJson(json['team1']),
      team2: Team.fromJson(json['team2']),
      score1: json['score1'],
      score2: json['score2'],
      status: MatchStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      scheduledTime:
          json['scheduledTime'] != null
              ? DateTime.parse(json['scheduledTime'])
              : null,
      courtNumber: json['courtNumber'],
      winner: json['winner'] != null ? Team.fromJson(json['winner']) : null,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1': team1.toJson(),
      'team2': team2.toJson(),
      'score1': score1,
      'score2': score2,
      'status': status.toString().split('.').last,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'courtNumber': courtNumber,
      'winner': winner?.toJson(),
    };
  }
}

enum TournamentType { singles, doubles }

enum GenderRestriction { male, female, mixed }

enum TournamentStatus { preparing, ongoing, completed, cancelled }

enum MatchStatus { scheduled, ongoing, completed, cancelled }
