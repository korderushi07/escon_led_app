import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/device_provider.dart';
import 'screens/connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: EsconLedApp(),
    ),
  );
}

class EsconLedApp extends ConsumerWidget {
  const EsconLedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRootScreen(),
    );
  }
}

class AppRootScreen extends ConsumerWidget {
  const AppRootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);

    // Initial loading state while restoring connection
    if (deviceState.status == DeviceConnectionStatus.connecting &&
        deviceState.activeDevice == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              SizedBox(height: 16),
              Text(
                'Connecting to ESCON LED...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (deviceState.status == DeviceConnectionStatus.connected) {
      return const DashboardScreen();
    }

    return const ConnectionScreen();
  }
}
