import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../providers/price_provider.dart';
import '../utils/theme.dart';
import '../widgets/connection_status.dart';
import '../widgets/price_card.dart';
import '../widgets/primary_button.dart';
import 'connection_screen.dart';
import 'device_screen.dart';
import 'update_price_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial prices upon dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(priceProvider.notifier).fetchPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final priceState = ref.watch(priceProvider);

    final isConnected = deviceState.status == DeviceConnectionStatus.connected;
    final deviceName = deviceState.activeDevice?.deviceName ?? 'ESCON LED';
    final deviceId = deviceState.activeDevice?.deviceId ?? 'ESCON-001';

    final petrolPrice = priceState.prices?.petrol ?? '103.50';
    final dieselPrice = priceState.prices?.diesel ?? '91.20';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(deviceName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ConnectionStatusBadge(
              isConnected: isConnected,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeviceScreen()),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Device Information',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeviceScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (isConnected) {
              await ref.read(priceProvider.notifier).fetchPrices();
            } else {
              await ref.read(deviceProvider.notifier).connectToDevice(deviceState.currentIp);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disconnected Warning Banner if connection drops
                if (!isConnected) ...[
                  Card(
                    color: const Color(0xFFFEF2F2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: AppTheme.statusDisconnected),
                              SizedBox(width: 8),
                              Text(
                                'LED display is not reachable.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.statusDisconnected,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Unable to connect to the LED display. Check the Wi-Fi connection and try again.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reconnect'),
                                onPressed: () {
                                  ref.read(deviceProvider.notifier).connectToDevice(deviceState.currentIp);
                                },
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                child: const Text('Change Connection'),
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Error Snackbar Banner if any
                if (priceState.errorMessage != null && isConnected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.statusDisconnected, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            priceState.errorMessage!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price Cards
                PriceCard(
                  fuelType: FuelType.petrol,
                  price: petrolPrice,
                  isLoading: priceState.isFetching,
                ),
                const SizedBox(height: 16),
                PriceCard(
                  fuelType: FuelType.diesel,
                  price: dieselPrice,
                  isLoading: priceState.isFetching,
                ),

                const SizedBox(height: 28),

                // Primary Button: UPDATE PRICES
                PrimaryButton(
                  label: 'UPDATE PRICES',
                  icon: Icons.edit_note_rounded,
                  onPressed: isConnected
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UpdatePriceScreen(
                                initialPetrol: petrolPrice,
                                initialDiesel: dieselPrice,
                              ),
                            ),
                          );
                        }
                      : null,
                ),

                const SizedBox(height: 32),

                // Device Info Details Footer Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SYSTEM DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Device', deviceId),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Connection',
                          isConnected ? 'Connected (${deviceState.currentIp})' : 'Disconnected',
                          isBadge: true,
                          isConnected: isConnected,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow('Last updated', priceState.formattedLastUpdated),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBadge = false, bool isConnected = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        if (isBadge)
          ConnectionStatusBadge(isConnected: isConnected, label: value)
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
      ],
    );
  }
}
