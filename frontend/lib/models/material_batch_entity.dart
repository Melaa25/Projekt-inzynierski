import 'package:equatable/equatable.dart';

import 'location_entity.dart';
import 'material_movement_entity.dart';
import 'material_type_entity.dart';
import 'batch_status.dart';

class MaterialBatchEntity extends Equatable {
  final int id;
  final String type;
  final int? materialId;
  final MaterialTypeEntity? material;
  final String batchCode;
  final int quantity;
  final double? totalWeight;
  final int? currentLocationId;
  final LocationEntity? currentLocation;
  final String status;
  final DateTime? createdAt;
  final List<MaterialMovementEntity>? movements;

  const MaterialBatchEntity({
    required this.id,
    required this.type,
    this.materialId,
    this.material,
    required this.batchCode,
    required this.quantity,
    this.totalWeight,
    this.currentLocationId,
    this.currentLocation,
    this.status = BatchStatus.inStock,
    this.createdAt,
    this.movements,
  });

  bool get isWaste => type == 'waste';

  String get displayName => isWaste ? 'Odpady' : (material?.name ?? 'Materiał');

  @override
  List<Object?> get props => [
        id,
        type,
        materialId,
        material,
        batchCode,
        quantity,
        totalWeight,
        currentLocationId,
        currentLocation,
        status,
        createdAt,
        movements,
      ];
}