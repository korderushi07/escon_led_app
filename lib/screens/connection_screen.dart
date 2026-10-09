import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/primary_button.dart';
import 'dashboard_screen.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController(text: AppConstants.defaultEsp32Ip);
  bool _showManualIpFallback = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  void _handleConnect(String ip) async {
    final success = await ref.read(deviceProvider.notifier).connectToDevice(ip);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final isSearching = deviceState.status == DeviceConnectionStatus.searching;
    final isConnecting = deviceState.status == DeviceConnectionStatus.connecting;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Brand / App Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cell_tower_rounded,
                    size: 54,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ESCON LED CONTROLLER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect your LED display to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // Primary Search Button
              PrimaryButton(
                label: isSearching ? 'Searching...' : 'Search for LED',
                icon: isSearching ? null : Icons.search_rounded,
                isLoading: isSearching,
                onPressed: () {
                  ref.read(deviceProvider.notifier).searchForDevices();
                },
              ),

              const SizedBox(height: 24),

              // Search Status & Results Container
              if (deviceState.status == DeviceConnectionStatus.searching) ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Searching local network for ESCON LED controller...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (deviceState.discoveredDevices.isNotEmpty) ...[
                const Text(
                  'DISCOVERED DEVICES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ...deviceState.discoveredDevices.map((device) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                device.deviceName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.statusConnected.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: AppTheme.statusConnected),
                                    SizedBox(width: 4),
                                    Text(
                                      'Connected',
                                      style: TextStyle(
                                        color: AppTheme.statusConnected,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Device ID: ${device.deviceId} • IP: ${device.ipAddress}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: isConnecting ? 'Connecting...' : 'Connect',
                            isLoading: isConnecting,
                            onPressed: () => _handleConnect(device.ipAddress),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else if (deviceState.status == DeviceConnectionStatus.failed &&
                  deviceState.errorMessage != null) ...[
                Card(
                  color: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.statusDisconnected,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            deviceState.errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Manual IP Fallback Section
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showManualIpFallback = !_showManualIpFallback;
                    });
                  },
                  icon: Icon(
                    _showManualIpFallback
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text(
                    _showManualIpFallback
                        ? 'Hide Manual IP Option'
                        : 'Cannot find LED? Enter IP Address manually',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              if (_showManualIpFallback) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESP32 IP ADDRESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ipController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 192.168.4.1',
                            prefixIcon: Icon(Icons.wifi_rounded, color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Connect via IP',
                          isLoading: isConnecting,
                          onPressed: () => _handleConnect(_ipController.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Demo / Simulator Mode Toggle (Useful for testing offline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science_outlined, size: 18, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Text(
                          'Demo Simulator Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: deviceState.useMockMode,
                      activeThumbColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        ref.read(deviceProvider.notifier).toggleMockMode(val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
