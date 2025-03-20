class Category {
  final int id;
  final String name;
  final int numberOfPlayer; // 1: Singles, 2: Doubles
  final int sex; // 0: Male, 1: Female, 2: Mixed

  Category({
    required this.id,
    required this.name,
    required this.numberOfPlayer,
    required this.sex,
  });

  // Tạo từ JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      numberOfPlayer: json['number_of_player'] ?? 1,
      sex: json['sex'] ?? 0,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_of_player': numberOfPlayer,
      'sex': sex,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Category copyWith({int? id, String? name, int? numberOfPlayer, int? sex}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      numberOfPlayer: numberOfPlayer ?? this.numberOfPlayer,
      sex: sex ?? this.sex,
    );
  }
}
