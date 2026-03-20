import 'package:invoice_ninja_client/src/models/api_datetime.dart';
import 'package:invoice_ninja_client/src/models/invoice_invitation.dart';
import 'package:invoice_ninja_client/src/models/invoice_line_item.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Invoice (`/api/v1/invoices`).
class Invoice {
  const Invoice({
    required this.id,
    this.clientId,
    this.number,
    this.date,
    this.dueDate,
    this.statusId,
    this.updatedAt,
    this.createdAt,
    this.amount,
    this.balance,
    this.publicNotes,
    this.privateNotes,
    this.lineItems = const [],
    this.invitations = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final items = <InvoiceLineItem>[];
    final raw = json['line_items'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          items.add(InvoiceLineItem.fromJson(e));
        } else if (e is Map) {
          items.add(InvoiceLineItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } else if (raw is Map) {
      for (final e in raw.values) {
        if (e is Map<String, dynamic>) {
          items.add(InvoiceLineItem.fromJson(e));
        } else if (e is Map) {
          items.add(InvoiceLineItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final invitations = <InvoiceInvitation>[];
    final invRaw = json['invitations'];
    if (invRaw is List) {
      for (final e in invRaw) {
        if (e is Map<String, dynamic>) {
          invitations.add(InvoiceInvitation.fromJson(e));
        } else if (e is Map) {
          invitations.add(
            InvoiceInvitation.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    final amt = json['amount'];
    final bal = json['balance'];

    return Invoice(
      id: readString(json, 'id') ?? '',
      clientId: readString(json, 'client_id'),
      number: readString(json, 'number'),
      date: parseApiCalendarDate(json['date']),
      dueDate: parseApiCalendarDate(json['due_date']),
      statusId: readInt(json, 'status_id'),
      updatedAt: parseApiInstant(json['updated_at']),
      createdAt: parseApiInstant(json['created_at']),
      amount: amt is num ? amt.toDouble() : double.tryParse('$amt'),
      balance: bal is num ? bal.toDouble() : double.tryParse('$bal'),
      publicNotes: readString(json, 'public_notes'),
      privateNotes: readString(json, 'private_notes'),
      lineItems: items,
      invitations: invitations,
    );
  }

  final String id;
  final String? clientId;
  final String? number;

  /// Invoice date (calendar day, local).
  final DateTime? date;

  /// Due date (calendar day, local).
  final DateTime? dueDate;

  final int? statusId;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  /// Total amount when returned by GET invoice.
  final double? amount;

  /// Balance due when returned by GET invoice.
  final double? balance;

  final String? publicNotes;
  final String? privateNotes;
  final List<InvoiceLineItem> lineItems;

  /// Included by default on GET invoice.
  final List<InvoiceInvitation> invitations;
}
