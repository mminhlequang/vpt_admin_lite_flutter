class ApiConstants {
  // Base URL cho API
  static const String baseUrl = 'https://familyworld.xyz/api';

  // API key
  static const String apiKey = 'whC]#}Z:&IP-tm7&Po_>y5qxB:ZVe^aQ';
 

  // Main endpoints
  static const String players = '/players';
  static const String tournaments = '/tournament';
  static const String videos = '/videos';
 
  // Pagination
  static const int defaultPageSize = 10;
  static const int defaultPage = 1;
  static const int maxPageSize = 100;
}

class AppConstants { 

  // Các thông số khác
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 100;
  static const int maxTeamName = 50;
}

class ErrorMessages {
  static const String connectionError = 'Không thể kết nối tới máy chủ';
  static const String authenticationError = 'Vui lòng đăng nhập để tiếp tục';
  static const String generalError = 'Đã xảy ra lỗi, vui lòng thử lại sau';
  static const String validationError =
      'Vui lòng kiểm tra lại thông tin đã nhập';
  static const String notFoundError = 'Không tìm thấy dữ liệu yêu cầu';
}

class UIConstants {
  // Các kích thước
  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;

  static const double smallRadius = 4.0;
  static const double defaultRadius = 8.0;
  static const double largeRadius = 16.0;

  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;

  // Thời gian animation
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}
