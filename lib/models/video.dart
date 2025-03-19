class Video {
  final int id;
  final String name;
  final String type;
  final String video;
  final String? avatar;
  final String? createdAt;

  Video({
    required this.id,
    required this.name,
    required this.type,
    required this.video,
    this.avatar,
    this.createdAt,
  });

  // Tạo từ JSON
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'youtube',
      video: json['video'] ?? '',
      avatar: json['avatar'],
      createdAt: json['created_at'] ?? '',
      );
  }

  // Chuyển đổi thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'video': video,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }

  // Tạo bản sao với một số thuộc tính được cập nhật
  Video copyWith({
    int? id,
    String? name,
    String? type,
    String? video,
    String? avatar,
    String? createdAt,
  }) {
    return Video(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      video: video ?? this.video,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
