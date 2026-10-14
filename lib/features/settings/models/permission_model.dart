class PermissionDefinitionModel {
  final String id;
  final String name;
  final String description;
  final String module;

  const PermissionDefinitionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.module,
  });

  factory PermissionDefinitionModel.fromJson(Map<String, dynamic> json) {
    return PermissionDefinitionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      module: json['module']?.toString() ?? 'General',
    );
  }
}
