class PriceModel {
  final String petrol;
  final String diesel;
  final DateTime? lastUpdated;

  const PriceModel({
    required this.petrol,
    required this.diesel,
    this.lastUpdated,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      petrol: json['petrol']?.toString() ?? '0.00',
      diesel: json['diesel']?.toString() ?? '0.00',
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'petrol': petrol,
        'diesel': diesel,
      };

  PriceModel copyWith({
    String? petrol,
    String? diesel,
    DateTime? lastUpdated,
  }) {
    return PriceModel(
      petrol: petrol ?? this.petrol,
      diesel: diesel ?? this.diesel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
