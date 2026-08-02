import 'material_batch_entity.dart';
import 'material_type_model.dart';
import 'material_movement_model.dart';
import 'location_model.dart';
import 'batch_status.dart';

class MaterialBatchModel extends MaterialBatchEntity {
  const MaterialBatchModel({
    required super.id,
    required super.type,
    super.materialId,
    super.material,
    required super.batchCode,
    required super.quantity,
    super.totalWeight,
    super.currentLocationId,
    super.currentLocation,
    super.status,
    super.createdAt,
    super.movements,
  });

  factory MaterialBatchModel.fromJson(Map<String, dynamic> json) {
    final materialJson = json['material'] as Map<String, dynamic>?;
    final locationJson = json['current_location'] as Map<String, dynamic>?;
    final movementsJson = json['movements'] as List<dynamic>?;

    return MaterialBatchModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'material',
      materialId: json['material_id'] as int?,
      material: materialJson == null ? null : MaterialTypeModel.fromJson(materialJson),
      batchCode: json['batch_code'] as String,
      quantity: json['quantity'] as int? ?? 0,
      totalWeight: _toNullableDouble(json['total_weight']),
      currentLocationId: json['current_location_id'] as int?,
      currentLocation: locationJson == null ? null : LocationModel.fromJson(locationJson),
      status: json['status'] as String? ?? BatchStatus.inStock,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'] as String),
      movements: movementsJson == null
          ? null
          : movementsJson.map((e) => MaterialMovementModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}