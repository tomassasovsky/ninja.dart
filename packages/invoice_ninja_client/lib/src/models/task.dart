import 'package:invoice_ninja_client/src/models/api_datetime.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/models/time_log_entry.dart';

/// Task (`/api/v1/tasks`).
class Task {
  Task({
    required this.id,
    this.clientId,
    this.projectId,
    this.assignedUserId,
    this.description,
    this.rate = 0,
    this.timeLog = const [],
    this.duration,
    this.invoiceId,
    this.invoiced,
    this.number,
    this.updatedAt,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: readString(json, 'id') ?? '',
      clientId: readString(json, 'client_id'),
      projectId: readString(json, 'project_id'),
      assignedUserId: readString(json, 'assigned_user_id'),
      description: readString(json, 'description'),
      rate: readDouble(json, 'rate'),
      timeLog: parseTimeLogRaw(json['time_log']),
      duration: readInt(json, 'duration'),
      invoiceId: readString(json, 'invoice_id'),
      invoiced: readBool(json, 'invoiced'),
      number: readString(json, 'number'),
      updatedAt: parseApiInstant(json['updated_at']),
      createdAt: parseApiInstant(json['created_at']),
    );
  }

  final String id;
  final String? clientId;
  final String? projectId;
  final String? assignedUserId;
  final String? description;
  final double rate;

  /// Decoded `time_log` segments (start/end Unix seconds).
  final List<TimeLogEntry> timeLog;

  /// Duration in seconds when set by API.
  final int? duration;
  final String? invoiceId;
  final bool? invoiced;
  final String? number;
  final DateTime? updatedAt;
  final DateTime? createdAt;
}
