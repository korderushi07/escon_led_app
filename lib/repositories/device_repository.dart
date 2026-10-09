import '../models/device_model.dart';
import '../models/price_model.dart';
import '../services/esp32_service.dart';
import '../services/device_discovery_service.dart';

abstract class DeviceRepository {
  Future<DeviceModel> getStatus(String ipAddress);
  Future<PriceModel> getPrices(String ipAddress);
  Future<bool> updatePrices({
    required String ipAddress,
    required String petrol,
    required String diesel,
  });
  Future<List<DeviceModel>> discoverDevices({String? preferredIp});
}

/// Local ESP32 Implementation of DeviceRepository
class ESP32LocalRepository implements DeviceRepository {
  final ESP32Service _esp32service;
  final DeviceDiscoveryService _discoveryService;

  ESP32LocalRepository({
    ESP32Service? esp32service,
    DeviceDiscoveryService? discoveryService,
  })  : _esp32service = esp32service ?? ESP32Service(),
        _discoveryService = discoveryService ?? DeviceDiscoveryService();

  @override
  Future<DeviceModel> getStatus(String ipAddress) {
    return _esp32service.getDeviceStatus(ipAddress);
  }

  @override
  Future<PriceModel> getPrices(String ipAddress) {
    return _esp32service.getPrices(ipAddress);
  }

  @override
  Future<bool> updatePrices({
    required String ipAddress,
    required String petrol,
    required String diesel,
  }) {
    return _esp32service.updatePrices(
      ipAddress: ipAddress,
      petrol: petrol,
      diesel: diesel,
    );
  }

  @override
  Future<List<DeviceModel>> discoverDevices({String? preferredIp}) {
    return _discoveryService.discoverDevices(preferredIp: preferredIp);
  }
}
