class TourPackage {
  final int id;
  final String name;
  final int? categoryId;
  final int? tourId;
  final num? price;
  final int enable; // 0: Disabled, 1: Enabled

  TourPackage({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.tourId,
    required this.price,
    this.enable = 1,
  });

  // Tạo từ JSON
  factory TourPackage.fromJson(Map<String, dynamic> json) {
    return TourPackage(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      categoryId:
          json['category_id'] is String
              ? int.parse(json['category_id'])
              : json['category_id'],
      tourId:
          json['tour_id'] is String
              ? int.parse(json['tour_id'])
              : json['tour_id'],
      price:
          json['price'] is String
              ? double.parse(json['price'])
              : json['price'].toDouble(),
      enable: json['enable'] ?? 1,
    );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'tour_id': tourId,
      'price': price,
      'enable': enable,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  TourPackage copyWith({
    int? id,
    String? name,
    int? categoryId,
    int? tourId,
    double? price,
    int? enable,
  }) {
    return TourPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      tourId: tourId ?? this.tourId,
      price: price ?? this.price,
      enable: enable ?? this.enable,
    );
  }
}
