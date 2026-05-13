import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

import '../../features/sassa/services/sassa_api_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'checkSassaStatusTask') {
        final prefs = await SharedPreferences.getInstance();
        final idToTrack = prefs.getString('tracked_sassa_id');
        final phoneToTrack = prefs.getString('tracked_sassa_phone');
        final lastStatus = prefs.getString('last_sassa_status');
        
        if (idToTrack != null && phoneToTrack != null) {
           final api = SassaApiService();
           try {
             final result = await api.checkStatus(idNumber: idToTrack, phoneNumber: phoneToTrack);
             final currentStatus = result['outcome'];
             
             if (currentStatus != null && currentStatus != lastStatus) {
                final notificationService = NotificationService();
                await notificationService.init();
                await notificationService.showNotification(
                  id: 1,
                  title: 'SASSA Status Update',
                  body: 'Your SRD grant status has changed to $currentStatus.',
                );
                await prefs.setString('last_sassa_status', currentStatus);
             }
           } catch(e) {
              debugPrint('Background SASSA check failed: $e');
           }
        }
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Workmanager task failed: $e');
      return Future.value(false);
    }
  });
}


class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerSassaTask() async {
    await Workmanager().registerPeriodicTask(
      'sassa_status_check_1',
      'checkSassaStatusTask',
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelSassaTask() async {
    await Workmanager().cancelByUniqueName('sassa_status_check_1');
  }
}
