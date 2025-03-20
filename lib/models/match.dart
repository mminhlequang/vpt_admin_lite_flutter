import 'package:flutter/foundation.dart';
import 'team.dart';

enum MatchStatus {
  pending, // Chưa diễn ra
  ongoing, // Đang diễn ra
  completed, // Đã kết thúc
  cancelled, // Đã hủy
}

class Match {
  final int id;
  final int roundId;
  final int? team1Id;
  final int? team2Id;
  final String? stadium;
  final DateTime scheduledTime;
  final MatchStatus matchStatus;
  final int? team1Score;
  final int? team2Score;
  final int? winnerId;
  final Team? team1;
  final Team? team2;

  Match({
    required this.id,
    required this.roundId,
    this.team1Id,
    this.team2Id,
    this.stadium,
    required this.scheduledTime,
    this.matchStatus = MatchStatus.pending,
    this.team1Score,
    this.team2Score,
    this.winnerId,
    this.team1,
    this.team2,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as int,
      roundId: json['round_id'] as int,
      team1Id: json['team1_id'] as int?,
      team2Id: json['team2_id'] as int?,
      stadium: json['stadium'] as String?,
      scheduledTime:
          json['scheduled_time'] != null
              ? DateTime.parse(json['scheduled_time'] as String)
              : DateTime.now(),
      matchStatus: _parseStatus(json['match_status'] as String?),
      team1Score: json['team1_score'] as int?,
      team2Score: json['team2_score'] as int?,
      winnerId: json['winner_id'] as int?,
      team1: json['team1'] != null ? Team.fromJson(json['team1']) : null,
      team2: json['team2'] != null ? Team.fromJson(json['team2']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'round_id': roundId,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'stadium': stadium,
      'scheduled_time': scheduledTime.toIso8601String(),
      'match_status': describeEnum(matchStatus),
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner_id': winnerId,
      // Không đưa team1 và team2 vào JSON để tránh dư thừa
    };
  }

  Match copyWith({
    int? id,
    int? roundId,
    int? team1Id,
    int? team2Id,
    String? stadium,
    DateTime? scheduledTime,
    MatchStatus? matchStatus,
    int? team1Score,
    int? team2Score,
    int? winnerId,
    Team? team1,
    Team? team2,
    bool clearTeam1 = false,
    bool clearTeam2 = false,
  }) {
    return Match(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      stadium: stadium ?? this.stadium,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      matchStatus: matchStatus ?? this.matchStatus,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      winnerId: winnerId ?? this.winnerId,
      team1: clearTeam1 ? null : team1 ?? this.team1,
      team2: clearTeam2 ? null : team2 ?? this.team2,
    );
  }

  static MatchStatus _parseStatus(String? status) {
    if (status == null) return MatchStatus.pending;

    switch (status.toLowerCase()) {
      case 'ongoing':
        return MatchStatus.ongoing;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      case 'pending':
      default:
        return MatchStatus.pending;
    }
  }
}
