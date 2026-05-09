import 'material_entity.dart';
import 'material_status.dart';
import 'location_model.dart';

class MaterialModel extends MaterialEntity {
  const MaterialModel({
    required super.id,
    required super.name,
    required super.serialNumber,
    required super.weight,
    required super.length,
    super.location,
    super.status,
    super.currentLocation,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    final currentLocationJson = json['current_location'] as Map<String, dynamic>?;

    return MaterialModel(
      id: json['id'] as int,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String,
      weight: _toDouble(json['weight']),
      length: _toDouble(json['length']),
      location: json['location'] as String?,
      status: (json['status'] as String?) ?? MaterialStatus.inStock,
      currentLocation: currentLocationJson == null ? null : LocationModel.fromJson(currentLocationJson),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}