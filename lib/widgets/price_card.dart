import 'package:flutter/material.dart';
import '../utils/theme.dart';

enum FuelType { petrol, diesel }

class PriceCard extends StatelessWidget {
  final FuelType fuelType;
  final String price;
  final bool isLoading;

  const PriceCard({
    super.key,
    required this.fuelType,
    required this.price,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPetrol = fuelType == FuelType.petrol;
    final title = isPetrol ? 'PETROL' : 'DIESEL';
    final accentColor = isPetrol ? AppTheme.petrolColor : AppTheme.dieselColor;
    final iconData = isPetrol ? Icons.local_gas_station_rounded : Icons.local_shipping_rounded;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withAlpha(50),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconData,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isLoading
                ? const SizedBox(
                    height: 54,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ L',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
