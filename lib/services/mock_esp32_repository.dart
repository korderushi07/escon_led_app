import 'dart:async';
import '../models/device_model.dart';
import '../models/price_model.dart';
import '../repositories/device_repository.dart';

class MockESP32Repository implements DeviceRepository {
  String _petrol = '103.50';
  String _diesel = '91.20';
  final bool _connected = true;

  @override
  Future<DeviceModel> getStatus(String ipAddress) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return DeviceModel(
      deviceId: 'ESCON-001',
      deviceName: 'ESCON LED',
      connected: _connected,
      ipAddress: ipAddress.isEmpty ? '192.168.4.1' : ipAddress,
      firmwareVersion: '1.0.0',
      displaySize: '64 × 16',
      lastConnectedAt: DateTime.now(),
    );
  }

  @override
  Future<PriceModel> getPrices(String ipAddress) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PriceModel(
      petrol: _petrol,
      diesel: _diesel,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<bool> updatePrices({
    required String ipAddress,
    required String petrol,
    required String diesel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _petrol = petrol;
    _diesel = diesel;
    return true;
  }

  @override
  Future<List<DeviceModel>> discoverDevices({String? preferredIp}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      DeviceModel(
        deviceId: 'ESCON-001',
        deviceName: 'ESCON LED',
        connected: true,
        ipAddress: preferredIp ?? '192.168.4.1',
        firmwareVersion: '1.0.0',
        displaySize: '64 × 16',
        lastConnectedAt: DateTime.now(),
      ),
    ];
  }
}
