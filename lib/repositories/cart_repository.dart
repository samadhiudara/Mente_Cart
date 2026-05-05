import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../utils/api_failure.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<CartModel> getCart() async {
    try {
      final response = await _apiClient.dio.get('/cart');
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CartModel> addItem({
    required String serviceId,
    required String slotDate,
    required String slotTime,
    int quantity = 1,
  }) async {
    try {
      final response = await _apiClient.dio.post('/cart/items', data: {
        'serviceId': serviceId,
        'slotDate': slotDate,
        'slotTime': slotTime,
        'quantity': quantity,
      });
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CartModel> updateItem(
    String itemId, {
    String? slotDate,
    String? slotTime,
    int? quantity,
  }) async {
    try {
      final response =
          await _apiClient.dio.patch('/cart/items/$itemId', data: {
        if (slotDate != null) 'slotDate': slotDate,
        if (slotTime != null) 'slotTime': slotTime,
        if (quantity != null) 'quantity': quantity,
      });
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<CartModel> removeItem(String itemId) async {
    try {
      final response =
          await _apiClient.dio.delete('/cart/items/$itemId');
      return CartModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
