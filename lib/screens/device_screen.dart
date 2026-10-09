import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../providers/price_provider.dart';
import '../utils/theme.dart';
import '../widgets/connection_status.dart';
import '../widgets/primary_button.dart';
import 'connection_screen.dart';

class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);
    final priceState = ref.watch(priceProvider);

    final isConnected = deviceState.status == DeviceConnectionStatus.connected;
    final device = deviceState.activeDevice;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Device Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hardware Header Card
              Card(
                color: AppTheme.primaryBlueDark,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            device?.deviceName ?? 'ESCON LED DISPLAY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ConnectionStatusBadge(
                            isConnected: isConnected,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Device ID: ${device?.deviceId ?? 'ESCON-001'}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'HARDWARE SPECIFICATIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSpecRow('Device ID', device?.deviceId ?? 'ESCON-001'),
                      const Divider(height: 24),
                      _buildSpecRow('Device Name', device?.deviceName ?? 'ESCON LED'),
                      const Divider(height: 24),
                      _buildSpecRow('Firmware Version', device?.firmwareVersion ?? '1.0.0'),
                      const Divider(height: 24),
                      _buildSpecRow('Display Matrix', device?.displaySize ?? '64 × 16 (2 × P10)'),
                      const Divider(height: 24),
                      _buildSpecRow('Display Driver', 'DMD32 (Arduino C++)'),
                      const Divider(height: 24),
                      _buildSpecRow('Microcontroller', 'ESP32 Dual-Core'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'NETWORK STATUS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSpecRow('IP Address', deviceState.currentIp),
                      const Divider(height: 24),
                      _buildSpecRow('Connection State', isConnected ? 'Connected' : 'Disconnected'),
                      const Divider(height: 24),
                      _buildSpecRow('Last Price Sync', priceState.formattedLastUpdated),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              if (isConnected) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Refresh Status & Prices'),
                  onPressed: () async {
                    await ref.read(deviceProvider.notifier).connectToDevice(deviceState.currentIp);
                    await ref.read(priceProvider.notifier).fetchPrices();
                  },
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Disconnect Device',
                  backgroundColor: AppTheme.statusDisconnected,
                  icon: Icons.link_off_rounded,
                  onPressed: () {
                    ref.read(deviceProvider.notifier).disconnect();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                    );
                  },
                ),
              ] else ...[
                PrimaryButton(
                  label: 'Connect to LED Display',
                  icon: Icons.wifi_rounded,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
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
