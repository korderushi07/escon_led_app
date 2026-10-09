import 'package:flutter_test/flutter_test.dart';
import 'package:escon_led_app/utils/validators.dart';

void main() {
  group('PriceValidator Tests', () {
    test('Valid prices should pass validation', () {
      expect(PriceValidator.validate('103.50', 'Petrol'), isNull);
      expect(PriceValidator.validate('91.2', 'Diesel'), isNull);
      expect(PriceValidator.validate('100', 'Petrol'), isNull);
      expect(PriceValidator.validate('999.99', 'Petrol'), isNull);
    });

    test('Empty or null prices should fail validation', () {
      expect(PriceValidator.validate('', 'Petrol'), 'Please enter Petrol price');
      expect(PriceValidator.validate('   ', 'Diesel'), 'Please enter Diesel price');
      expect(PriceValidator.validate(null, 'Petrol'), 'Please enter Petrol price');
    });

    test('Non-numeric or invalid format prices should fail validation', () {
      expect(PriceValidator.validate('abc', 'Petrol'), isNotNull);
      expect(PriceValidator.validate('103.50.1', 'Diesel'), isNotNull);
      expect(PriceValidator.validate('104.', 'Petrol'), isNotNull); // trailing dot
      expect(PriceValidator.validate('104.567', 'Petrol'), isNotNull); // > 2 decimal places
    });

    test('Zero or negative prices should fail validation', () {
      expect(PriceValidator.validate('0', 'Petrol'), 'Petrol price must be greater than ₹0.00');
      expect(PriceValidator.validate('-10', 'Diesel'), isNotNull);
    });

    test('Prices exceeding 999.99 or 6 chars should fail validation', () {
      expect(PriceValidator.validate('1000', 'Petrol'), isNotNull);
      expect(PriceValidator.validate('000104.5', 'Petrol'), 'Petrol price cannot exceed 6 characters');
    });

    test('Price normalization to 2 decimal places', () {
      expect(PriceValidator.normalize('103'), '103.00');
      expect(PriceValidator.normalize('103.5'), '103.50');
      expect(PriceValidator.normalize('103.50'), '103.50');
      expect(PriceValidator.normalize('91.2'), '91.20');
    });
  });
}
