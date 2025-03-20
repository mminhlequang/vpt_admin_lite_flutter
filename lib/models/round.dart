import 'match.dart';

class Round {
  final int id;
  final int? tournamentId;
  final String name;
  final DateTime startTime;
  final List<Match> matches;

  Round({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.startTime,
    this.matches = const [],
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    List<Match> matchesList = [];
    if (json['matches'] != null) {
      matchesList =
          (json['matches'] as List)
              .map((matchJson) => Match.fromJson(matchJson))
              .toList();
    }

    return Round(
      id: json['id'] as int,
      tournamentId: json['tournament_id'],
      name: json['name'] as String,
      startTime:
          json['start_time'] != null
              ? DateTime.parse(json['start_time'] as String)
              : DateTime.now(),
      matches: matchesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'matches': matches.map((match) => match.toJson()).toList(),
    };
  }

  Round copyWith({
    int? id,
    int? tournamentId,
    String? name,
    DateTime? startTime,
    List<Match>? matches,
  }) {
    return Round(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      matches: matches ?? this.matches,
    );
  }
}
