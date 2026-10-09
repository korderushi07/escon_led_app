import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';
import '../services/mock_esp32_repository.dart';
import '../utils/constants.dart';

enum DeviceConnectionStatus {
  disconnected,
  searching,
  connecting,
  connected,
  failed,
}

class DeviceState {
  final DeviceConnectionStatus status;
  final DeviceModel? activeDevice;
  final List<DeviceModel> discoveredDevices;
  final String? errorMessage;
  final String currentIp;
  final bool useMockMode;

  const DeviceState({
    required this.status,
    this.activeDevice,
    this.discoveredDevices = const [],
    this.errorMessage,
    this.currentIp = AppConstants.defaultEsp32Ip,
    this.useMockMode = false,
  });

  DeviceState copyWith({
    DeviceConnectionStatus? status,
    DeviceModel? activeDevice,
    List<DeviceModel>? discoveredDevices,
    String? errorMessage,
    String? currentIp,
    bool? useMockMode,
  }) {
    return DeviceState(
      status: status ?? this.status,
      activeDevice: activeDevice ?? this.activeDevice,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      errorMessage: errorMessage, // Allow clearing by passing null explicitly
      currentIp: currentIp ?? this.currentIp,
      useMockMode: useMockMode ?? this.useMockMode,
    );
  }
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  DeviceNotifier()
      : super(const DeviceState(
          status: DeviceConnectionStatus.disconnected,
        )) {
    _init();
  }

  DeviceRepository _getRepository() {
    if (state.useMockMode) {
      return MockESP32Repository();
    }
    return ESP32LocalRepository();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastIp = prefs.getString(AppConstants.keyLastIp) ?? AppConstants.defaultEsp32Ip;
    final mockMode = prefs.getBool(AppConstants.keyUseMockMode) ?? false;

    state = state.copyWith(
      currentIp: lastIp,
      useMockMode: mockMode,
    );

    // Attempt automatic quiet reconnect to last known IP
    await connectToDevice(lastIp, isAutoConnect: true);
  }

  Future<void> searchForDevices({String? targetIp}) async {
    state = state.copyWith(
      status: DeviceConnectionStatus.searching,
      errorMessage: null,
      discoveredDevices: [],
    );

    try {
      final repo = _getRepository();
      final devices = await repo.discoverDevices(preferredIp: targetIp ?? state.currentIp);

      if (devices.isNotEmpty) {
        state = state.copyWith(
          status: DeviceConnectionStatus.disconnected,
          discoveredDevices: devices,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: DeviceConnectionStatus.failed,
          discoveredDevices: [],
          errorMessage: AppConstants.errDeviceNotFound,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: DeviceConnectionStatus.failed,
        discoveredDevices: [],
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> connectToDevice(String ipAddress, {bool isAutoConnect = false}) async {
    final cleanIp = ipAddress.trim().isEmpty ? AppConstants.defaultEsp32Ip : ipAddress.trim();

    state = state.copyWith(
      status: DeviceConnectionStatus.connecting,
      errorMessage: null,
      currentIp: cleanIp,
    );

    try {
      final repo = _getRepository();
      final device = await repo.getStatus(cleanIp);

      state = state.copyWith(
        status: DeviceConnectionStatus.connected,
        activeDevice: device,
        errorMessage: null,
      );

      // Persist last successful IP & Device ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLastIp, cleanIp);
      await prefs.setString(AppConstants.keyLastDeviceId, device.deviceId);

      return true;
    } catch (e) {
      state = state.copyWith(
        status: DeviceConnectionStatus.failed,
        activeDevice: null,
        errorMessage: isAutoConnect
            ? 'LED display display is not reachable. Check Wi-Fi connection.'
            : e.toString(),
      );
      return false;
    }
  }

  void disconnect() {
    state = state.copyWith(
      status: DeviceConnectionStatus.disconnected,
      activeDevice: null,
      errorMessage: null,
    );
  }

  Future<void> toggleMockMode(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyUseMockMode, enable);

    state = state.copyWith(
      useMockMode: enable,
      status: DeviceConnectionStatus.disconnected,
      activeDevice: null,
    );

    if (enable) {
      await connectToDevice(AppConstants.defaultEsp32Ip);
    }
  }
}

final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  return DeviceNotifier();
});
