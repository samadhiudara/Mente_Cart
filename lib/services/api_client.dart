import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio _dio;
  final TokenStorage tokenStorage;

  // Change via --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

  ApiClient({required this.tokenStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(tokenStorage: tokenStorage),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        compact: true,
      ),
    ]);
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  _AuthInterceptor({required this.tokenStorage});

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      tokenStorage.clearToken();
    }
    handler.next(err);
  }
}
