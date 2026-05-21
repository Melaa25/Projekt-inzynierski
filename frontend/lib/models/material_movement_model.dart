import 'material_movement_entity.dart';
import 'location_model.dart';

class MaterialMovementModel extends MaterialMovementEntity {
  const MaterialMovementModel({
    required super.id,
    required super.materialId,
    super.userId,
    super.userName,
    required super.type,
    super.destination,
    super.note,
    super.previousStatus,
    super.newStatus,
    super.previousLocation,
    super.newLocation,
    required super.createdAt,
  });

  factory MaterialMovementModel.fromJson(Map<String, dynamic> json) {
    final previousLocationJson = json['previous_location'] as Map<String, dynamic>?;
    final newLocationJson = json['new_location'] as Map<String, dynamic>?;

    return MaterialMovementModel(
      id: json['id'] as int,
      materialId: json['material_id'] as int,
      userId: json['user_id'] as int?,
      userName: json['user'] is Map<String, dynamic> ? (json['user']['name'] as String?) : null,
      type: json['type'] as String,
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
