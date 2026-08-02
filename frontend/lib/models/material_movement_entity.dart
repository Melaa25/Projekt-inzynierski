import 'package:equatable/equatable.dart';

import 'material_batch_entity.dart';
import 'location_entity.dart';

class MaterialMovementEntity extends Equatable {
  final int id;
  final int? materialBatchId;
  final MaterialBatchEntity? batch;
  final int? userId;
  final String? userName;
  final String type;
  final int quantityDelta;
  final String? destination;
  final String? note;
  final String? previousStatus;
  final String? newStatus;
  final LocationEntity? previousLocation;
  final LocationEntity? newLocation;
  final DateTime createdAt;

  const MaterialMovementEntity({
    required this.id,
    this.materialBatchId,
    this.batch,
    this.userId,
    this.userName,
    required this.type,
    required this.quantityDelta,
    this.destination,
    this.note,
    this.previousStatus,
    this.newStatus,
    this.previousLocation,
    this.newLocation,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        materialBatchId,
        batch,
        userId,
        userName,
        type,
        quantityDelta,
        destination,
        note,
        previousStatus,
        newStatus,
        previousLocation,
        newLocation,
        createdAt,
      ];
}