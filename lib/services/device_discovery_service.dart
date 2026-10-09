import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';
import '../utils/constants.dart';
import 'wifi_service.dart';

class DeviceDiscoveryService {
  final http.Client _client;

  DeviceDiscoveryService({http.Client? client}) : _client = client ?? http.Client();

  /// Primary target candidate IPs & mDNS hosts for ESP32 AP mode
  static final List<String> defaultCandidates = [
    AppConstants.defaultEsp32Ip, // 192.168.4.1 (ESP32 AP Hotspot)
    'escon-led.local',           // mDNS fallback host
  ];

  /// Probes a single IP address for ESP32 status
  Future<DeviceModel?> probeIp(String ipAddress) async {
    await WifiService.ensureWifiBinding();
    var cleanIp = ipAddress.trim().replaceAll('http://', '').replaceAll('https://', '');
    if (cleanIp.endsWith('/')) {
      cleanIp = cleanIp.substring(0, cleanIp.length - 1);
    }

    final endpoints = [AppConstants.statusEndpoint, AppConstants.fallbackStatusEndpoint];

    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse('http://$cleanIp$endpoint');
        final response = await _client.get(uri).timeout(AppConstants.probeTimeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            return DeviceModel.fromJson(body, ipAddress: cleanIp);
          }
        }
      } catch (_) {
        // Continue to fallback or next probe
      }
    }
    return null;
  }

  /// Discovers ESP32 controllers on local AP network
  Future<List<DeviceModel>> discoverDevices({
    String? preferredIp,
    List<String>? customSubnetCandidates,
  }) async {
    final List<String> ipsToProbe = [];

    if (preferredIp != null && preferredIp.isNotEmpty) {
      ipsToProbe.add(preferredIp);
    }

    ipsToProbe.addAll(defaultCandidates);

    if (customSubnetCandidates != null) {
      ipsToProbe.addAll(customSubnetCandidates);
    }

    final uniqueIps = ipsToProbe.toSet().toList();

    // Probe candidates concurrently
    final List<Future<DeviceModel?>> tasks = uniqueIps.map((ip) => probeIp(ip)).toList();
    final results = await Future.wait(tasks);

    final List<DeviceModel> foundDevices = results.whereType<DeviceModel>().toList();
    return foundDevices;
  }
}
