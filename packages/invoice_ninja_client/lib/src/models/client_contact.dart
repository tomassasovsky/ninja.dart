import 'package:invoice_ninja_client/src/models/json_read.dart';

/// Client contact (`contacts[]` on a client).
class ClientContact {
  const ClientContact({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.isPrimary,
    this.sendEmail,
  });

  factory ClientContact.fromJson(Map<String, dynamic> json) {
    return ClientContact(
      id: readString(json, 'id') ?? '',
      email: readString(json, 'email'),
      firstName: readString(json, 'first_name'),
      lastName: readString(json, 'last_name'),
      isPrimary: readBool(json, 'is_primary'),
      sendEmail: readBool(json, 'send_email'),
    );
  }

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool? isPrimary;
  final bool? sendEmail;

  String get displayName {
    final a = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return a.isEmpty ? '(no name)' : a;
  }
}
