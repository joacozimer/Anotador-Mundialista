import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:io' show Platform;

class UpdateHelper {
  static Future<void> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Prioridad de actualización (opcional en Google Play Console)
        // 0-5. Usamos 4+ para actualización inmediata, <4 para flexible.
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('Error al buscar actualizaciones: $e');
    }
  }
}
