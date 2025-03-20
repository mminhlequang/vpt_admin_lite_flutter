import 'player.dart';

class Tournament {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int type; // 1: singles, 2: doubles
  final List<String>? genderRestriction; // ['male', 'female', 'mixed']
  final int numberOfTeams;
  final List<Team> teams;
  final List<Match> matches;
  final TournamentStatus status;
  final String? imageUrl;
  final String? description;
  final int? categoryId;
  final String? city;
  final String? surface;
  final double? prize;
  final int? packageId;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.genderRestriction,
    required this.numberOfTeams,
    this.teams = const [],
    this.matches = const [],
    this.status = TournamentStatus.preparing,
    this.imageUrl,
    this.description,
    this.categoryId,
    this.city,
    this.surface,
    this.prize,
    this.packageId,
  });

  // Tạo từ JSON
  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'])
              : DateTime.now(),
      endDate:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'])
              : DateTime.now().add(Duration(days: 1)),
      type:
          json['type'] is String
              ? int.parse(json['type'])
              : (json['type'] ?? 1),
      genderRestriction:
          json['genderRestriction'] is List
              ? (json['genderRestriction'] as List).cast<String>()
              : json['genderRestriction'] is String
              ? [json['genderRestriction']]
              : ['mixed'],
      numberOfTeams:
          json['numberOfTeams'] is String
              ? int.parse(json['numberOfTeams'])
              : (json['numberOfTeams'] ?? 2),
      teams:
          json['teams'] is List
              ? (json['teams'] as List)
                  .map((team) => Team.fromJson(team))
                  .toList()
              : [],
      matches:
          json['matches'] is List
              ? (json['matches'] as List)
                  .map((match) => Match.fromJson(match))
                  .toList()
              : [],
      status:
          json['status'] != null
              ? TournamentStatus.values.firstWhere(
                (e) => e.toString().split('.').last == json['status'],
                orElse: () => TournamentStatus.preparing,
              )
              : TournamentStatus.preparing,
      imageUrl: json['imageUrl'] ?? json['image_url'],
      description: json['description'],
      categoryId:
          json['categoryId'] is String
              ? int.parse(json['categoryId'])
              : json['categoryId'],
      city: json['city'],
      surface: json['surface'],
      prize:
          json['prize'] != null
              ? double.tryParse(json['prize'].toString())
              : null,
      packageId:
          json['packageId'] is String
              ? int.parse(json['packageId'])
              : json['packageId'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
      'genderRestriction': genderRestriction,
      'numberOfTeams': numberOfTeams,
      'teams': teams.map((team) => team.toJson()).toList(),
      'matches': matches.map((match) => match.toJson()).toList(),
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'description': description,
      'categoryId': categoryId,
      'city': city,
      'surface': surface,
      'prize': prize,
      'packageId': packageId,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Tournament copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? type,
    List<String>? genderRestriction,
    int? numberOfTeams,
    List<Team>? teams,
    List<Match>? matches,
    TournamentStatus? status,
    String? imageUrl,
    String? description,
    int? categoryId,
    String? city,
    String? surface,
    double? prize,
    int? packageId,
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
      categoryId: categoryId ?? this.categoryId,
      city: city ?? this.city,
      surface: surface ?? this.surface,
      prize: prize ?? this.prize,
      packageId: packageId ?? this.packageId,
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
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? 'Đội không tên',
      players:
          json['players'] is List
              ? (json['players'] as List)
                  .map((player) => Player.fromJson(player))
                  .toList()
              : [],
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
      id: json['id']?.toString() ?? '0',
      team1:
          json['team1'] is Map
              ? Team.fromJson(json['team1'])
              : Team(id: '0', name: 'Đội 1', players: []),
      team2:
          json['team2'] is Map
              ? Team.fromJson(json['team2'])
              : Team(id: '0', name: 'Đội 2', players: []),
      score1:
          json['score1'] is String
              ? int.tryParse(json['score1'])
              : json['score1'],
      score2:
          json['score2'] is String
              ? int.tryParse(json['score2'])
              : json['score2'],
      status:
          json['status'] != null
              ? MatchStatus.values.firstWhere(
                (e) => e.toString().split('.').last == json['status'],
                orElse: () => MatchStatus.scheduled,
              )
              : MatchStatus.scheduled,
      scheduledTime:
          json['scheduledTime'] != null
              ? DateTime.tryParse(json['scheduledTime'])
              : null,
      courtNumber: json['courtNumber']?.toString(),
      winner: json['winner'] is Map ? Team.fromJson(json['winner']) : null,
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

enum TournamentStatus { preparing, ongoing, completed, cancelled }

enum MatchStatus { scheduled, ongoing, completed, cancelled }
