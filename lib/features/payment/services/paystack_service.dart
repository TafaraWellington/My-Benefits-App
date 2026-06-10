import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paystackServiceProvider = Provider<PaystackService>((ref) {
  return PaystackService();
});

class PaystackService {
  final Dio _dio = Dio();
  
  // URL of the backend API (Next.js web_dashboard or hosted server)
  // Dev local host (Android emulator uses 10.0.2.2, iOS simulator uses localhost)
  static const String _backendUrl = 'http://10.0.2.2:3000'; // Update this to your production backend URL when deploying

  Future<String?> initializeTransaction({
    required double amount,
    required String email,
    required String reference,
    required String userId,
    required int credits,
    String? tier,
  }) async {
    try {
      final response = await _dio.post(
        '$_backendUrl/api/payment/initialize',
        data: {
          'email': email,
          'amount': amount,
          'reference': reference,
          'userId': userId,
          'credits': credits,
          if (tier != null) 'tier': tier,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data']['authorization_url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Paystack Initialize Error: $e');
      return null;
    }
  }

  // Verification is now handled automatically via webhook on the server side.
  // This client-side helper can check the user's updated profile directly from Supabase.
  @Deprecated('Use profile sync/check instead, as webhooks process payments securely')
  Future<bool> verifyTransaction(String reference) async {
    // Left as a stub or can query client's backend status if needed
    return false;
  }
}

