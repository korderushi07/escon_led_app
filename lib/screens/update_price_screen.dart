import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_provider.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/led_preview_card.dart';
import '../widgets/primary_button.dart';

class UpdatePriceScreen extends ConsumerStatefulWidget {
  final String initialPetrol;
  final String initialDiesel;

  const UpdatePriceScreen({
    super.key,
    required this.initialPetrol,
    required this.initialDiesel,
  });

  @override
  ConsumerState<UpdatePriceScreen> createState() => _UpdatePriceScreenState();
}

class _UpdatePriceScreenState extends ConsumerState<UpdatePriceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _petrolController;
  late TextEditingController _dieselController;

  @override
  void initState() {
    super.initState();
    _petrolController = TextEditingController(text: widget.initialPetrol);
    _dieselController = TextEditingController(text: widget.initialDiesel);

    _petrolController.addListener(_updatePreview);
    _dieselController.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {});
  }

  @override
  void dispose() {
    _petrolController.removeListener(_updatePreview);
    _dieselController.removeListener(_updatePreview);
    _petrolController.dispose();
    _dieselController.dispose();
    super.dispose();
  }

  void _onUpdatePressed() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final normalizedPetrol = PriceValidator.normalize(_petrolController.text);
      final normalizedDiesel = PriceValidator.normalize(_dieselController.text);

      _showConfirmationDialog(normalizedPetrol, normalizedDiesel);
    }
  }

  void _showConfirmationDialog(String petrol, String diesel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.live_tv_rounded, color: AppTheme.primaryBlue),
              SizedBox(width: 10),
              Text(
                'Confirm Price Update',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will update the connected LED display.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildConfirmRow('PETROL', '₹$petrol', AppTheme.petrolColor),
                    const Divider(height: 16),
                    _buildConfirmRow('DIESEL', '₹$diesel', AppTheme.dieselColor),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _executePriceUpdate(petrol, diesel);
              },
              child: const Text('Confirm Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Future<void> _executePriceUpdate(String petrol, String diesel) async {
    final success = await ref.read(priceProvider.notifier).updatePrices(
          petrol: petrol,
          diesel: diesel,
        );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(petrol, diesel);
    } else {
      final errorMsg = ref.read(priceProvider).errorMessage ?? 'Price update failed';
      _showErrorSnackBar(errorMsg);
    }
  }

  void _showSuccessDialog(String petrol, String diesel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.statusConnected, size: 28),
              SizedBox(width: 10),
              Text(
                'Prices Updated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Petrol ₹$petrol',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.petrolColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Diesel ₹$diesel',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dieselColor),
              ),
              const SizedBox(height: 12),
              const Text(
                'LED display has been updated successfully.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusConnected,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Return to dashboard
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.statusDisconnected,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: _onUpdatePressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceState = ref.watch(priceProvider);
    final isUpdating = priceState.isUpdating;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Update Prices'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LedPreviewCard(
                  petrol: _petrolController.text,
                  diesel: _dieselController.text,
                ),
                const SizedBox(height: 24),

                const Text(
                  'ENTER NEW PRICES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // PETROL PRICE INPUT FIELD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_gas_station_rounded, color: AppTheme.petrolColor),
                            SizedBox(width: 8),
                            Text(
                              'PETROL PRICE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.petrolColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _petrolController,
                          enabled: !isUpdating,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 8, top: 12),
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            hintText: '103.50',
                          ),
                          validator: (val) => PriceValidator.validate(val, 'Petrol'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // DIESEL PRICE INPUT FIELD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_shipping_rounded, color: AppTheme.dieselColor),
                            SizedBox(width: 8),
                            Text(
                              'DIESEL PRICE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dieselColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dieselController,
                          enabled: !isUpdating,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$')),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 8, top: 12),
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            hintText: '91.20',
                          ),
                          validator: (val) => PriceValidator.validate(val, 'Diesel'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Primary Button: UPDATE LED
                PrimaryButton(
                  label: isUpdating ? 'UPDATING LED...' : 'UPDATE LED',
                  icon: isUpdating ? null : Icons.send_rounded,
                  isLoading: isUpdating,
                  onPressed: isUpdating ? null : _onUpdatePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
