import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WifiService {
  static bool _forced = false;

  /// Forces socket traffic over Wi-Fi when connected to a local AP with no internet.
  /// Bypasses Android's auto-routing to mobile data.
  static Future<void> ensureWifiBinding() async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
      if (!_forced) {
        await WiFiForIoTPlugin.forceWifiUsage(true);
        _forced = true;
      }
    } on MissingPluginException catch (_) {
      // Ignored in unit test environments
    } catch (e) {
      debugPrint('WifiService.ensureWifiBinding error: $e');
    }
  }

  /// Releases forced Wi-Fi socket binding.
  static Future<void> releaseWifiBinding() async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
      if (_forced) {
        await WiFiForIoTPlugin.forceWifiUsage(false);
        _forced = false;
      }
    } on MissingPluginException catch (_) {
      // Ignored in unit test environments
    } catch (e) {
      debugPrint('WifiService.releaseWifiBinding error: $e');
    }
  }

  /// Attempts to programmatically connect to an ESCON LED Wi-Fi AP.
  static Future<bool> connectToSsid(String ssid, {String password = ''}) async {
    if (kIsWeb) return false;
    try {
      if (!Platform.isAndroid) return false;
      final success = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: password.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
        joinOnce: true,
      );
      if (success) {
        await ensureWifiBinding();
      }
      return success;
    } on MissingPluginException catch (_) {
      return false;
    } catch (e) {
      debugPrint('WifiService.connectToSsid error: $e');
      return false;
    }
  }
}
