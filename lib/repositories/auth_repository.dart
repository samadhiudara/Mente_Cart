import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';
import '../utils/api_failure.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  TokenStorage get _tokenStorage => _apiClient.tokenStorage;

  Future<({UserModel user, String token})> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await _tokenStorage.saveToken(token);
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        token: token,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<({UserModel user, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await _tokenStorage.saveToken(token);
      return (
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        token: token,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return null;
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return UserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clearToken();
        return null;
      }
      throw mapDioError(e);
    }
  }

  Future<void> logout() => _tokenStorage.clearToken();
}
