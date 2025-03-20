class Team {
  final String id;
  final String name;
  final int registrationStatus; // 0: pending, 1: approved, 2: rejected
  final int paymentStatus; // 0: unpaid, 1: pending, 2: completed, 3: failed
  final String? paymentCode; // Mã code để xác định callback từ cổng thanh toán
  final DateTime? registrationDate;
  final int? tournamentId;
  final int? playerId1;
  final int? playerId2;
  final int? packageId;

  Team({
    required this.id,
    required this.name,
    this.registrationStatus = 0,
    this.paymentStatus = 0,
    this.paymentCode,
    this.registrationDate,
    this.tournamentId,
    this.playerId1,
    this.playerId2,
    this.packageId,
  });

  // Tạo từ JSON
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      registrationStatus: json['registration_status'] ?? 0,
      paymentStatus: json['payment_status'] ?? 0,
      paymentCode: json['payment_code'],
      registrationDate:
          json['registration_date'] != null
              ? DateTime.parse(json['registration_date'])
              : null,
      tournamentId: json['tournament_id'],
      playerId1: json['player_id1'],
      playerId2: json['player_id2'],
      packageId: json['package_id'],
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'registration_status': registrationStatus,
      'payment_status': paymentStatus,
      'payment_code': paymentCode,
      'registration_date': registrationDate?.toIso8601String(),
      'tournament_id': tournamentId,
      'player_id1': playerId1,
      'player_id2': playerId2,
      'package_id': packageId,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Team copyWith({
    String? id,
    String? name,
    int? registrationStatus,
    int? paymentStatus,
    String? paymentCode,
    DateTime? registrationDate,
    int? tournamentId,
    int? playerId1,
    int? playerId2,
    int? packageId,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentCode: paymentCode ?? this.paymentCode,
      registrationDate: registrationDate ?? this.registrationDate,
      tournamentId: tournamentId ?? this.tournamentId,
      playerId1: playerId1 ?? this.playerId1,
      playerId2: playerId2 ?? this.playerId2,
      packageId: packageId ?? this.packageId,
    );
  }
}

// Enum cho trạng thái đăng ký và thanh toán
enum RegistrationStatus { pending, approved, rejected }

enum PaymentStatus { unpaid, pending, completed, failed }
