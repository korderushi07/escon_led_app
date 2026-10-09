import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/price_model.dart';
import '../repositories/device_repository.dart';
import '../services/mock_esp32_repository.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'device_provider.dart';

class PriceState {
  final PriceModel? prices;
  final bool isFetching;
  final bool isUpdating;
  final bool? updateSuccess;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdated;

  const PriceState({
    this.prices,
    this.isFetching = false,
    this.isUpdating = false,
    this.updateSuccess,
    this.errorMessage,
    this.successMessage,
    this.lastUpdated,
  });

  String get formattedLastUpdated {
    if (lastUpdated == null) return 'Not updated yet';
    return DateFormat('hh:mm a').format(lastUpdated!);
  }

  PriceState copyWith({
    PriceModel? prices,
    bool? isFetching,
    bool? isUpdating,
    bool? updateSuccess,
    String? errorMessage,
    String? successMessage,
    DateTime? lastUpdated,
  }) {
    return PriceState(
      prices: prices ?? this.prices,
      isFetching: isFetching ?? this.isFetching,
      isUpdating: isUpdating ?? this.isUpdating,
      updateSuccess: updateSuccess,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class PriceNotifier extends StateNotifier<PriceState> {
  final Ref _ref;

  PriceNotifier(this._ref) : super(const PriceState()) {
    _init();
  }

  DeviceRepository _getRepository() {
    final deviceState = _ref.read(deviceProvider);
    if (deviceState.useMockMode) {
      return MockESP32Repository();
    }
    return ESP32LocalRepository();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(AppConstants.keyLastUpdatedTime);
    if (timeStr != null) {
      final parsedTime = DateTime.tryParse(timeStr);
      state = state.copyWith(lastUpdated: parsedTime);
    }
  }

  Future<void> fetchPrices() async {
    final deviceState = _ref.read(deviceProvider);
    if (deviceState.status != DeviceConnectionStatus.connected) {
      return;
    }

    state = state.copyWith(
      isFetching: true,
      errorMessage: null,
    );

    try {
      final repo = _getRepository();
      final prices = await repo.getPrices(deviceState.currentIp);

      final now = DateTime.now();
      state = state.copyWith(
        prices: prices,
        isFetching: false,
        lastUpdated: now,
        errorMessage: null,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLastUpdatedTime, now.toIso8601String());
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> updatePrices({
    required String petrol,
    required String diesel,
  }) async {
    final deviceState = _ref.read(deviceProvider);
    if (deviceState.status != DeviceConnectionStatus.connected) {
      state = state.copyWith(
        errorMessage: 'LED display is not reachable. Check your Wi-Fi connection.',
        updateSuccess: false,
      );
      return false;
    }

    final normalizedPetrol = PriceValidator.normalize(petrol);
    final normalizedDiesel = PriceValidator.normalize(diesel);

    state = state.copyWith(
      isUpdating: true,
      errorMessage: null,
      successMessage: null,
      updateSuccess: null,
    );

    try {
      final repo = _getRepository();
      final success = await repo.updatePrices(
        ipAddress: deviceState.currentIp,
        petrol: normalizedPetrol,
        diesel: normalizedDiesel,
      );

      if (success) {
        final now = DateTime.now();
        final newPrices = PriceModel(
          petrol: normalizedPetrol,
          diesel: normalizedDiesel,
          lastUpdated: now,
        );

        state = state.copyWith(
          prices: newPrices,
          isUpdating: false,
          updateSuccess: true,
          successMessage: 'LED display has been updated successfully.',
          lastUpdated: now,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyLastUpdatedTime, now.toIso8601String());

        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          updateSuccess: false,
          errorMessage: AppConstants.errUpdateFailed,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        updateSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void resetUpdateState() {
    state = state.copyWith(
      updateSuccess: null,
      errorMessage: null,
      successMessage: null,
    );
  }
}

final priceProvider = StateNotifierProvider<PriceNotifier, PriceState>((ref) {
  return PriceNotifier(ref);
});
