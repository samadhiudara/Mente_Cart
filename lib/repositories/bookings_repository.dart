import 'package:dio/dio.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../utils/api_failure.dart';

class BookingsRepository {
  final ApiClient _apiClient;

  BookingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<BookingModel> checkout({required String paymentMethod}) async {
    try {
      final response = await _apiClient.dio.post('/bookings/checkout', data: {
        'paymentMethod': paymentMethod,
      });
      return BookingModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<BookingModel>> listBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings');
      return (response.data['data'] as List<dynamic>)
          .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<BookingModel> getBooking(String id) async {
    try {
      final response = await _apiClient.dio.get('/bookings/$id');
      return BookingModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<BookingModel> cancelBooking(String id, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post('/bookings/$id/cancel',
          data: {if (reason != null) 'reason': reason});
      return BookingModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
