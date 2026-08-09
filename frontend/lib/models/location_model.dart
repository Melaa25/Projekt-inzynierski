import 'location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    super.code,
    required super.name,
    super.type,
    super.parentId,
    super.description,
    super.childrenCount,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      type: json['type'],
      parentId: json['parent_id'],
      description: json['description'],
      childrenCount: json['children_count'] ?? 0,
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