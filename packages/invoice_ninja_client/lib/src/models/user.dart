import 'package:invoice_ninja_client/src/models/json_read.dart';

/// User (`/api/v1/users`).
class User {
  const User({required this.id, this.firstName, this.lastName, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: readString(json, 'id') ?? '',
      firstName: readString(json, 'first_name'),
      lastName: readString(json, 'last_name'),
      email: readString(json, 'email'),
    );
  }

  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
}
