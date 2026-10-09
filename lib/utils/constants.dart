class AppConstants {
  static const String appName = 'ESCON LED Controller';
  static const String defaultEsp32Ip = '192.168.4.1';
  static const int defaultPort = 80;

  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration probeTimeout = Duration(milliseconds: 1500);

  // Endpoints
  static const String statusEndpoint = '/api/v1/status';
  static const String pricesEndpoint = '/api/v1/prices';
  static const String fallbackStatusEndpoint = '/api/status';
  static const String fallbackPricesEndpoint = '/api/prices';

  // SharedPreferences Keys
  static const String keyLastIp = 'last_known_ip';
  static const String keyLastDeviceId = 'last_device_id';
  static const String keyLastUpdatedTime = 'last_updated_time';
  static const String keyUseMockMode = 'use_mock_mode';

  // Error Messages
  static const String errUnableToConnect =
      'Unable to connect to the LED display. Check your Wi-Fi connection and try again.';
  static const String errTimeout =
      'Join the ESCON_LED_XXXXXX Wi-Fi and turn off mobile data, then retry';
  static const String errDeviceNotFound =
      'No ESCON LED display found on the current network. Please make sure your phone is connected to the ESCON LED Wi-Fi.';
  static const String errInvalidResponse =
      'Received an invalid response from the LED display.';
  static const String errUpdateFailed =
      'Failed to update prices on the LED display. Please try again.';
}
