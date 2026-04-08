import '../../domain/entities/material_entity.dart';

class MaterialModel extends MaterialEntity {
  const MaterialModel({
    required super.id,
    required super.name,
    required super.serialNumber,
    required super.weight,
    required super.length,
    super.location,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as int,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String,
      weight: _toDouble(json['weight']),
      length: _toDouble(json['length']),
      location: json['location'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    // Laravel moze zwrocic pola dziesietne jako liczbe albo jako tekst.
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
