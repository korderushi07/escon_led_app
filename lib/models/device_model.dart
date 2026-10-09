class DeviceModel {
  final String deviceId;
  final String deviceName;
  final bool connected;
  final String ipAddress;
  final String firmwareVersion;
  final String displaySize;
  final DateTime? lastConnectedAt;

  const DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.connected,
    required this.ipAddress,
    this.firmwareVersion = '1.0.0',
    this.displaySize = '64 × 16',
    this.lastConnectedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json, {required String ipAddress}) {
    return DeviceModel(
      deviceId: json['deviceId']?.toString() ?? 'ESCON-001',
      deviceName: json['deviceName']?.toString() ?? 'ESCON LED',
      connected: json['connected'] == true || json['connected'] == 'true',
      ipAddress: ipAddress,
      firmwareVersion: json['firmwareVersion']?.toString() ?? '1.0.0',
      displaySize: json['displaySize']?.toString() ?? '64 × 16',
      lastConnectedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'connected': connected,
        'ipAddress': ipAddress,
        'firmwareVersion': firmwareVersion,
        'displaySize': displaySize,
        'lastConnectedAt': lastConnectedAt?.toIso8601String(),
      };

  DeviceModel copyWith({
    String? deviceId,
    String? deviceName,
    bool? connected,
    String? ipAddress,
    String? firmwareVersion,
    String? displaySize,
    DateTime? lastConnectedAt,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      connected: connected ?? this.connected,
      ipAddress: ipAddress ?? this.ipAddress,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      displaySize: displaySize ?? this.displaySize,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}
