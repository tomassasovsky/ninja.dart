import 'package:invoice_ninja_client/src/models/client_contact.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Client (`/api/v1/clients`).
class Client {
  const Client({
    required this.id,
    this.name,
    this.number,
    this.contacts = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final contacts = <ClientContact>[];
    final raw = json['contacts'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          contacts.add(ClientContact.fromJson(e));
        } else if (e is Map) {
          contacts.add(ClientContact.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return Client(
      id: readString(json, 'id') ?? '',
      name: readString(json, 'name'),
      number: readString(json, 'number'),
      contacts: contacts,
    );
  }

  final String id;
  final String? name;
  final String? number;

  /// Included by default on GET client.
  final List<ClientContact> contacts;
}
