import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';
import '../models/price_model.dart';
import '../utils/constants.dart';
import 'wifi_service.dart';

class ESP32Exception implements Exception {
  final String message;
  final String? technicalDetails;

  ESP32Exception(this.message, [this.technicalDetails]);

  @override
  String toString() => message;
}

class ESP32Service {
  final http.Client _client;

  ESP32Service({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String ipAddress, String endpoint) {
    var cleanIp = ipAddress.trim().replaceAll('http://', '').replaceAll('https://', '');
    if (cleanIp.endsWith('/')) {
      cleanIp = cleanIp.substring(0, cleanIp.length - 1);
    }
    return Uri.parse('http://$cleanIp$endpoint');
  }

  /// GET /api/v1/status
  Future<DeviceModel> getDeviceStatus(String ipAddress) async {
    await WifiService.ensureWifiBinding();
    final uri = _buildUri(ipAddress, AppConstants.statusEndpoint);
    try {
      final response = await _client
          .get(uri)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return DeviceModel.fromJson(body, ipAddress: ipAddress);
        }
        throw ESP32Exception(AppConstants.errInvalidResponse);
      } else if (response.statusCode == 400) {
        final body = _safeDecodeJson(response.body);
        final errorMsg = body?['error']?.toString() ?? body?['message']?.toString() ?? AppConstants.errUnableToConnect;
        throw ESP32Exception(errorMsg, 'HTTP 400: ${response.body}');
      } else {
        throw ESP32Exception(
          'Server Error (${response.statusCode}): ${response.reasonPhrase ?? "Unable to connect"}',
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      throw ESP32Exception(AppConstants.errTimeout);
    } on SocketException catch (e) {
      throw ESP32Exception('Unable to reach LED display. Check Wi-Fi connection.', e.message);
    } on FormatException catch (e) {
      throw ESP32Exception(AppConstants.errInvalidResponse, e.message);
    } catch (e) {
      if (e is ESP32Exception) rethrow;
      throw ESP32Exception('Network Error: ${e.toString()}');
    }
  }

  /// GET /api/v1/prices
  Future<PriceModel> getPrices(String ipAddress) async {
    await WifiService.ensureWifiBinding();
    final uri = _buildUri(ipAddress, AppConstants.pricesEndpoint);
    try {
      final response = await _client
          .get(uri)
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return PriceModel.fromJson(body);
        }
        throw ESP32Exception(AppConstants.errInvalidResponse);
      } else if (response.statusCode == 400) {
        final body = _safeDecodeJson(response.body);
        final errorMsg = body?['error']?.toString() ?? body?['message']?.toString() ?? 'Failed to retrieve prices';
        throw ESP32Exception(errorMsg, 'HTTP 400: ${response.body}');
      } else {
        throw ESP32Exception(
          'Server Error (${response.statusCode}): Failed to retrieve prices',
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      throw ESP32Exception(AppConstants.errTimeout);
    } on SocketException catch (e) {
      throw ESP32Exception('Unable to reach LED display. Check Wi-Fi connection.', e.message);
    } on FormatException catch (e) {
      throw ESP32Exception(AppConstants.errInvalidResponse, e.message);
    } catch (e) {
      if (e is ESP32Exception) rethrow;
      throw ESP32Exception('Network Error: ${e.toString()}');
    }
  }

  /// POST /api/v1/prices
  Future<bool> updatePrices({
    required String ipAddress,
    required String petrol,
    required String diesel,
  }) async {
    await WifiService.ensureWifiBinding();
    final uri = _buildUri(ipAddress, AppConstants.pricesEndpoint);
    final payload = jsonEncode({
      'petrol': petrol,
      'diesel': diesel,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(AppConstants.requestTimeout);

      final body = _safeDecodeJson(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body != null && body['success'] == false) {
          final errorMsg = body['error']?.toString() ?? body['message']?.toString() ?? AppConstants.errUpdateFailed;
          throw ESP32Exception(errorMsg);
        }
        return true;
      } else if (response.statusCode == 400) {
        final errorMsg = body?['error']?.toString() ?? body?['message']?.toString() ?? AppConstants.errUpdateFailed;
        throw ESP32Exception(errorMsg, 'HTTP 400: ${response.body}');
      } else {
        throw ESP32Exception(
          'Server Error (${response.statusCode}): ${AppConstants.errUpdateFailed}',
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      throw ESP32Exception(AppConstants.errTimeout);
    } on SocketException catch (e) {
      throw ESP32Exception('Unable to reach LED display. Check Wi-Fi connection.', e.message);
    } on FormatException catch (e) {
      throw ESP32Exception(AppConstants.errInvalidResponse, e.message);
    } catch (e) {
      if (e is ESP32Exception) rethrow;
      throw ESP32Exception(AppConstants.errUpdateFailed, e.toString());
    }
  }

  Map<String, dynamic>? _safeDecodeJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}
