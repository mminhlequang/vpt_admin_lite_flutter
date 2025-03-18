import 'package:dio/dio.dart';
import '../utils/constants.dart';

class APIService {
  final Dio _dio = Dio();

  // Singleton pattern
  static final APIService _instance = APIService._internal();

  factory APIService() {
    return _instance;
  }

  APIService._internal() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Thêm interceptor để xử lý token, logging, retry, v.v.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Thêm token xác thực nếu có
          // options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Xử lý lỗi chung
          return handler.next(e);
        },
      ),
    );
  }

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Xử lý lỗi
  void _handleError(DioException error) {
    String errorMessage = 'Đã xảy ra lỗi không xác định';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Không thể kết nối đến máy chủ';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _handleStatusCode(
          error.response?.statusCode,
          error.response?.data,
        );
        break;
      case DioExceptionType.unknown:
        if (error.message != null &&
            error.message!.contains('SocketException')) {
          errorMessage = 'Không có kết nối mạng';
        }
        break;
      default:
        errorMessage = 'Đã xảy ra lỗi không xác định';
        break;
    }

    throw Exception(errorMessage);
  }

  // Xử lý mã trạng thái HTTP
  String _handleStatusCode(int? statusCode, dynamic errorResponse) {
    switch (statusCode) {
      case 400:
        return errorResponse['message'] ?? 'Yêu cầu không hợp lệ';
      case 401:
        return 'Yêu cầu xác thực';
      case 403:
        return 'Không được phép truy cập';
      case 404:
        return 'Không tìm thấy tài nguyên';
      case 500:
        return 'Lỗi máy chủ';
      default:
        return 'Đã xảy ra lỗi với mã: $statusCode';
    }
  }
}
