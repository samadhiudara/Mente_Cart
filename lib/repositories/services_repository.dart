import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../utils/api_failure.dart';

class ServicesRepository {
  final ApiClient _apiClient;

  ServicesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<PaginatedServices> listServices({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get('/services', queryParameters: {
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      return PaginatedServices.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ServiceModel> getService(String id) async {
    try {
      final response = await _apiClient.dio.get('/services/$id');
      return ServiceModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/services/categories');
      return (response.data['data'] as List<dynamic>)
          .map((c) => c as String)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
