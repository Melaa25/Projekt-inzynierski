import 'package:equatable/equatable.dart';

import 'material_entity.dart';
import 'location_entity.dart';

class MaterialMovementEntity extends Equatable {
  final int id;
  final int materialId;
  final int? userId;
  final String? userName;
  final String type;
  final String? destination;
  final String? note;
  final String? previousStatus;
  final String? newStatus;
  final LocationEntity? previousLocation;
  final LocationEntity? newLocation;
  final DateTime createdAt;

  const MaterialMovementEntity({
    required this.id,
    required this.materialId,
    this.userId,
    this.userName,
    required this.type,
    this.destination,
    this.note,
    this.previousStatus,
    this.newStatus,
    this.previousLocation,
    this.newLocation,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, materialId, userId, userName, type, destination, note, previousStatus, newStatus, previousLocation, newLocation, createdAt];
}
