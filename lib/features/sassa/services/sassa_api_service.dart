import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sassaApiServiceProvider = Provider<SassaApiService>((ref) {
  return SassaApiService();
});

class SassaApiService {
  final Dio _dio;

  SassaApiService() : _dio = Dio() {
    _dio.options.baseUrl = 'https://api.mock-sassa-service.co.za/v1'; // Dummy endpoint
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Map<String, dynamic>> checkStatus({
    required String idNumber,
    required String phoneNumber,
  }) async {
    try {
      // In a real scenario, this would be a real GET or POST request.
      // final response = await _dio.post('/status', data: {
      //   'idNumber': idNumber,
      //   'phoneNumber': phoneNumber,
      // });
      // return response.data;

      // Simulated network delay and mock response for architecture
      await Future.delayed(const Duration(seconds: 2));

      if (idNumber == '0000000000000') {
        throw Exception('Invalid ID Number provided by server.');
      }

      final outcome = DateTime.now().minute % 2 == 0 ? 'APPROVED' : 'PENDING';

      return {
        'month': 'May 2026',
        'outcome': outcome,
        'payDay': '2026-05-25',
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timed out. Please try again.');
      } else {
        throw Exception('Failed to communicate with SASSA servers.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
