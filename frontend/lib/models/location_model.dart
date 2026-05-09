import 'location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    super.code,
    required super.name,
    super.type,
    super.parentId,
    super.description,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      code: json['code'] as String?,
      name: json['name'] as String,
      type: json['type'] as String?,
      parentId: json['parent_id'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'parent_id': parentId,
      'description': description,
    };
  }
}
