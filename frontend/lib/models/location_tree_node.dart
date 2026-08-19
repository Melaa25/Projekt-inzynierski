import 'package:equatable/equatable.dart';

class LocationTreeNode extends Equatable {
  final int id;
  final String? code;
  final String name;
  final String type;
  final List<LocationTreeNode> children;

  const LocationTreeNode({
    required this.id,
    this.code,
    required this.name,
    required this.type,
    this.children = const [],
  });

  factory LocationTreeNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];

    return LocationTreeNode(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      type: json['type'] ?? '',
      children: childrenJson
          .map((e) => LocationTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, code, name, type, children];
}