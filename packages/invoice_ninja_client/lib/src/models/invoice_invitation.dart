import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Invitation row on an invoice (`invitations[]` on GET invoice).
class InvoiceInvitation {
  const InvoiceInvitation({
    required this.id,
    this.clientContactId,
    this.key,
    this.link,
  });

  factory InvoiceInvitation.fromJson(Map<String, dynamic> json) {
    return InvoiceInvitation(
      id: readString(json, 'id') ?? '',
      clientContactId: readString(json, 'client_contact_id'),
      key: readString(json, 'key'),
      link: readString(json, 'link'),
    );
  }

  final String id;
  final String? clientContactId;
  final String? key;
  final String? link;
}
