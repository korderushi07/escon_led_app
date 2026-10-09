import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:escon_led_app/services/esp32_service.dart';
import 'package:escon_led_app/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ESP32Service Tests', () {
    test('getDeviceStatus returns DeviceModel on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, AppConstants.statusEndpoint);
        return http.Response(
          '{"deviceId":"ESCON-001","deviceName":"ESCON LED","connected":true,"firmwareVersion":"1.0.0","displaySize":"64 x 16"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ESP32Service(client: mockClient);
      final device = await service.getDeviceStatus('192.168.4.1');

      expect(device.deviceId, 'ESCON-001');
      expect(device.deviceName, 'ESCON LED');
      expect(device.connected, isTrue);
    });

    test('getPrices returns PriceModel on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, AppConstants.pricesEndpoint);
        return http.Response(
          '{"petrol":"104.50","diesel":"92.30"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ESP32Service(client: mockClient);
      final prices = await service.getPrices('192.168.4.1');

      expect(prices.petrol, '104.50');
      expect(prices.diesel, '92.30');
    });

    test('updatePrices succeeds on HTTP 200 with success:true', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, AppConstants.pricesEndpoint);
        expect(request.method, 'POST');
        expect(request.headers['content-type'], contains('application/json'));
        expect(request.body, '{"petrol":"104.50","diesel":"92.30"}');

        return http.Response(
          '{"success":true,"message":"Prices updated","petrol":"104.50","diesel":"92.30"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ESP32Service(client: mockClient);
      final result = await service.updatePrices(
        ipAddress: '192.168.4.1',
        petrol: '104.50',
        diesel: '92.30',
      );

      expect(result, isTrue);
    });

    test('updatePrices surfaces body error field on HTTP 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success":false,"error":"Price exceeds maximum allowable threshold 999.99"}',
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ESP32Service(client: mockClient);

      expect(
        () async => await service.updatePrices(
          ipAddress: '192.168.4.1',
          petrol: '1000.00',
          diesel: '92.30',
        ),
        throwsA(isA<ESP32Exception>().having(
          (e) => e.message,
          'message',
          contains('Price exceeds maximum allowable threshold'),
        )),
      );
    });

    test('updatePrices throws timeout exception on TimeoutException', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(seconds: 6));
        return http.Response('{}', 200);
      });

      final service = ESP32Service(client: mockClient);

      expect(
        () async => await service.updatePrices(
          ipAddress: '192.168.4.1',
          petrol: '104.50',
          diesel: '92.30',
        ),
        throwsA(isA<ESP32Exception>().having(
          (e) => e.message,
          'message',
          contains('Join the ESCON_LED_XXXXXX Wi-Fi'),
        )),
      );
    });
  });
}
