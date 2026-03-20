import 'package:invoice_ninja_client/src/exceptions.dart';
import 'package:invoice_ninja_client/src/models/json_read.dart';
import 'package:invoice_ninja_client/src/models/user.dart';
import 'package:invoice_ninja_client/src/transport.dart';

class UsersApi {
  UsersApi(this._t);
  final InvoiceNinjaTransport _t;

  /// `GET /api/v1/users` (all pages)
  Future<List<User>> listAll([Map<String, String>? extraQuery]) async {
    final raw = await _t.fetchAllPages('/api/v1/users', extraQuery: extraQuery);
    return raw.map((e) => User.fromJson(asJsonMap(e))).toList();
  }

  /// Case-insensitive match on first + last name.
  Future<User> findByName(String firstName, String lastName) async {
    final users = await listAll();
    final fn = firstName.toLowerCase();
    final ln = lastName.toLowerCase();
    for (final u in users) {
      if ((u.firstName ?? '').toLowerCase() == fn &&
          (u.lastName ?? '').toLowerCase() == ln) {
        return u;
      }
    }
    final names = users.map((u) => '${u.firstName} ${u.lastName}').toList();
    throw LookupException(
      'User "$firstName $lastName" not found. Available: $names',
    );
  }
}
