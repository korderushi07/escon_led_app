import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final bool isConnected;
  final String label;
  final VoidCallback? onTap;

  const ConnectionStatusBadge({
    super.key,
    required this.isConnected,
    this.label = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppTheme.statusConnected : AppTheme.statusDisconnected;
    final text = label.isNotEmpty
        ? label
        : (isConnected ? 'Connected' : 'Disconnected');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
