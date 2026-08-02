import 'material_movement_entity.dart';
import 'material_batch_model.dart';
import 'location_model.dart';

class MaterialMovementModel extends MaterialMovementEntity {
  const MaterialMovementModel({
    required super.id,
    super.materialBatchId,
    super.batch,
    super.userId,
    super.userName,
    required super.type,
    required super.quantityDelta,
    super.destination,
    super.note,
    super.previousStatus,
    super.newStatus,
    super.previousLocation,
    super.newLocation,
    required super.createdAt,
  });

  factory MaterialMovementModel.fromJson(Map<String, dynamic> json) {
    final batchJson = json['batch'] as Map<String, dynamic>?;
    final previousLocationJson = json['previous_location'] as Map<String, dynamic>?;
    final newLocationJson = json['new_location'] as Map<String, dynamic>?;

    return MaterialMovementModel(
      id: json['id'] as int,
      materialBatchId: json['material_batch_id'] as int?,
      batch: batchJson == null ? null : MaterialBatchModel.fromJson(batchJson),
      userId: json['user_id'] as int?,
      userName: json['user'] is Map<String, dynamic> ? (json['user']['name'] as String?) : null,
      type: json['type'] as String,
      quantityDelta: json['quantity_delta'] as int? ?? 0,
      destination: json['destination'] as String?,
      note: json['note'] as String?,
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String?,
      previousLocation: previousLocationJson == null ? null : LocationModel.fromJson(previousLocationJson),
      newLocation: newLocationJson == null ? null : LocationModel.fromJson(newLocationJson),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}