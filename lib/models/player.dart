class Player {
  final int id;
  final int rank;
  final String name;
  final String? avatar;
  final String? email;
  final String? phone;
  final int? height;
  final int? weight;
  final String? paddle;
  final String? plays;
  final String? back_hand;
  final String? turned_pro;
  final String? birth_place;
  final String? birth_date;
  final int? age;
  final String? coach;
  final Region? region;
  final int sex; // 1: Nam, 2: Nữ
  final String? link_twitter;
  final String? link_facebook;
  final String? link_instagram;
  final String? link_youtube;
  final int total_win;
  final int total_lose;
  final int total_win_doubles;
  final int total_lose_doubles;
  final int favorite;
  final int active;

  // Các trường bổ sung cho việc đăng ký giải đấu
  final bool hasPaid;
  final RegistrationStatus status;
  final DateTime registrationDate;

  Player({
    required this.id,
    this.rank = 0,
    required this.name,
    this.avatar,
    this.email,
    this.phone,
    this.height,
    this.weight,
    this.paddle,
    this.plays,
    this.back_hand,
    this.turned_pro,
    this.birth_place,
    this.birth_date,
    this.age,
    this.coach,
    this.region,
    this.sex = 1, // Mặc định là Nam
    this.link_twitter,
    this.link_facebook,
    this.link_instagram,
    this.link_youtube,
    this.total_win = 0,
    this.total_lose = 0,
    this.total_win_doubles = 0,
    this.total_lose_doubles = 0,
    this.favorite = 0,
    this.active = 1,
    this.hasPaid = false,
    this.status = RegistrationStatus.pending,
    DateTime? registrationDate,
  }) : this.registrationDate = registrationDate ?? DateTime.now();

  // Hàm để lấy giới tính dưới dạng chuỗi 'male' hoặc 'female'
  String get gender => sex == 1 ? 'male' : 'female';

  // Tạo từ JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      rank: json['rank'] ?? 0,
      name: json['name'] ?? '',
      avatar: json['avatar'],
      email: json['email'] ?? '',
      phone: json['phone'],
      height: json['height'],
      weight: json['weight'],
      paddle: json['paddle'],
      plays: json['plays'],
      back_hand: json['back_hand'],
      turned_pro: json['turned_pro'],
      birth_place: json['birth_place'],
      birth_date: json['birth_date'],
      age: json['age'],
      coach: json['coach'],
      region: json['region'] != null ? Region.fromJson(json['region']) : null,
      sex: json['sex'] ?? 1,
      link_twitter: json['link_twitter'],
      link_facebook: json['link_facebook'],
      link_instagram: json['link_instagram'],
      link_youtube: json['link_youtube'],
      total_win: json['total_win'] ?? 0,
      total_lose: json['total_lose'] ?? 0,
      total_win_doubles: json['total_win_doubles'] ?? 0,
      total_lose_doubles: json['total_lose_doubles'] ?? 0,
      favorite: json['favorite'] ?? 0,
      active: json['active'] ?? 1,
      hasPaid: json['hasPaid'] ?? false,
      status: _parseStatus(json['status']),
      registrationDate:
          json['registrationDate'] != null
              ? DateTime.parse(json['registrationDate'])
              : null,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rank': rank,
      'name': name,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'height': height,
      'weight': weight,
      'paddle': paddle,
      'plays': plays,
      'back_hand': back_hand,
      'turned_pro': turned_pro,
      'birth_place': birth_place,
      'birth_date': birth_date,
      'age': age,
      'coach': coach,
      'region': region?.toJson(),
      'sex': sex,
      'link_twitter': link_twitter,
      'link_facebook': link_facebook,
      'link_instagram': link_instagram,
      'link_youtube': link_youtube,
      'total_win': total_win,
      'total_lose': total_lose,
      'total_win_doubles': total_win_doubles,
      'total_lose_doubles': total_lose_doubles,
      'favorite': favorite,
      'active': active,
      'hasPaid': hasPaid,
      'status': status.toString().split('.').last,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Player copyWith({
    int? id,
    int? rank,
    String? name,
    String? avatar,
    String? email,
    String? phone,
    int? height,
    int? weight,
    String? paddle,
    String? plays,
    String? back_hand,
    String? turned_pro,
    String? birth_place,
    String? birth_date,
    int? age,
    String? coach,
    Region? region,
    int? sex,
    String? link_twitter,
    String? link_facebook,
    String? link_instagram,
    String? link_youtube,
    int? total_win,
    int? total_lose,
    int? total_win_doubles,
    int? total_lose_doubles,
    int? favorite,
    int? active,
    bool? hasPaid,
    RegistrationStatus? status,
    DateTime? registrationDate,
  }) {
    return Player(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      paddle: paddle ?? this.paddle,
      plays: plays ?? this.plays,
      back_hand: back_hand ?? this.back_hand,
      turned_pro: turned_pro ?? this.turned_pro,
      birth_place: birth_place ?? this.birth_place,
      birth_date: birth_date ?? this.birth_date,
      age: age ?? this.age,
      coach: coach ?? this.coach,
      region: region ?? this.region,
      sex: sex ?? this.sex,
      link_twitter: link_twitter ?? this.link_twitter,
      link_facebook: link_facebook ?? this.link_facebook,
      link_instagram: link_instagram ?? this.link_instagram,
      link_youtube: link_youtube ?? this.link_youtube,
      total_win: total_win ?? this.total_win,
      total_lose: total_lose ?? this.total_lose,
      total_win_doubles: total_win_doubles ?? this.total_win_doubles,
      total_lose_doubles: total_lose_doubles ?? this.total_lose_doubles,
      favorite: favorite ?? this.favorite,
      active: active ?? this.active,
      hasPaid: hasPaid ?? this.hasPaid,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }

  static RegistrationStatus _parseStatus(String? status) {
    if (status == null) return RegistrationStatus.pending;

    switch (status.toLowerCase()) {
      case 'approved':
        return RegistrationStatus.approved;
      case 'rejected':
        return RegistrationStatus.rejected;
      default:
        return RegistrationStatus.pending;
    }
  }
}

class Region {
  final int id;
  final String name;
  final String? code;
  final String? continent;
  final String? avatar;

  Region({
    required this.id,
    required this.name,
    this.code,
    this.continent,
    this.avatar,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      code: json['code'],
      continent: json['continent'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'continent': continent,
      'avatar': avatar,
    };
  }
}

enum RegistrationStatus { pending, approved, rejected }
