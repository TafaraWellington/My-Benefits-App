import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paystackServiceProvider = Provider<PaystackService>((ref) {
  return PaystackService();
});

class PaystackService {
  // Replace with your actual public key from Paystack Dashboard
  static const String _publicKey = 'pk_live_f4d58086d2749877cfebee08d2552a049047d075';

  Future<bool> checkout(BuildContext context, {required double amount, required String email}) async {
    final completer = Completer<bool>();
    try {
      final reference = 'TRANS_${DateTime.now().millisecondsSinceEpoch}';
      
      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: _publicKey,
        customerEmail: email,
        context: context,
        amount: (amount * 100).toInt().toString(),
        reference: reference,
        onClosed: () {
          debugPrint('Payment modal closed');
          if (!completer.isCompleted) completer.complete(false);
        },
        onSuccess: () {
          debugPrint('Payment successful: $reference');
          if (!completer.isCompleted) completer.complete(true);
        },
      );

      return completer.future;
    } catch (e) {
      debugPrint('Paystack Error: $e');
      return false;
    }
  }
}
