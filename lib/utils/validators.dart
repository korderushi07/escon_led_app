class PriceValidator {
  static final RegExp _priceRegex = RegExp(r'^\d{1,3}(\.\d{1,2})?$');

  /// Validates that input is non-empty, matches ^\d{1,3}(\.\d{1,2})?$, length <= 6, > 0 and <= 999.99
  static String? validate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName price';
    }

    final cleanValue = value.trim();

    if (cleanValue.length > 6) {
      return '$fieldName price cannot exceed 6 characters';
    }

    if (!_priceRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid $fieldName price (e.g. 104.50, max 2 decimals)';
    }

    final doubleValue = double.tryParse(cleanValue);

    if (doubleValue == null) {
      return 'Please enter a valid numeric $fieldName price';
    }

    if (doubleValue <= 0) {
      return '$fieldName price must be greater than ₹0.00';
    }

    if (doubleValue > 999.99) {
      return '$fieldName price cannot exceed ₹999.99';
    }

    return null;
  }

  /// Formats any valid numeric string into exactly two decimal places.
  /// Example: "103" -> "103.00", "103.5" -> "103.50"
  static String normalize(String value) {
    final doubleValue = double.tryParse(value.trim()) ?? 0.0;
    return doubleValue.toStringAsFixed(2);
  }
}
