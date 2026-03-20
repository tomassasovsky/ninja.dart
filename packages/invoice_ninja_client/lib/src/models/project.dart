import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Project (`/api/v1/projects`).
class Project {
  const Project({required this.id, this.name, this.clientId, this.taskRate});

  factory Project.fromJson(Map<String, dynamic> json) {
    final tr = json['task_rate'];
    double? rate;
    if (tr is num) rate = tr.toDouble();
    if (tr is String) rate = double.tryParse(tr);

    return Project(
      id: readString(json, 'id') ?? '',
      name: readString(json, 'name'),
      clientId: readString(json, 'client_id'),
      taskRate: rate,
    );
  }

  final String id;
  final String? name;
  final String? clientId;
  final double? taskRate;
}
