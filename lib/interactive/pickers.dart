import 'package:invoice_ninja_client/invoice_ninja_client.dart';
import 'package:invoice_ninja_scripts/api_time.dart';
import 'package:invoice_ninja_scripts/task_invoice.dart';
import 'package:mason_logger/mason_logger.dart';

String _taskLabel(Task t) {
  final n = t.number ?? '?';
  final desc = (t.description ?? '').trim();
  final short = desc.length > 48 ? '${desc.substring(0, 48)}…' : desc;
  return '#$n ${short.isEmpty ? '(no description)' : short}';
}

Future<Client?> pickClient(InvoiceNinjaClient client, Logger log) async {
  final progress = log.progress('Loading clients');
  final all = await client.clients.listAll();
  progress.complete();
  if (all.isEmpty) {
    log.warn('No clients found.');
    return null;
  }
  final choices = <Object>[...all, pickCancel];
  final picked = log.chooseOne<Object>(
    'Select a client',
    choices: choices,
    display: (c) => c is PickCancel
        ? '— Cancel —'
        : '${(c as Client).name ?? '(no name)'} — #${c.number ?? "?"}',
  );
  if (picked is PickCancel) return null;
  return picked as Client;
}

Future<Project?> pickProjectForClient(
  InvoiceNinjaClient client,
  Logger log,
  String clientId,
) async {
  final progress = log.progress('Loading projects');
  final raw = await client.projects.listAll();
  progress.complete();
  final all = raw.where((x) => x.clientId == clientId).toList();
  if (all.isEmpty) {
    log.warn('No projects for this client.');
    return null;
  }
  final choices = <Object>[...all, pickCancel];
  final picked = log.chooseOne<Object>(
    'Select a project',
    choices: choices,
    display: (c) =>
        c is PickCancel ? '— Cancel —' : ((c as Project).name ?? '(no name)'),
  );
  if (picked is PickCancel) return null;
  return picked as Project;
}

Future<User?> pickUser(InvoiceNinjaClient client, Logger log) async {
  final progress = log.progress('Loading users');
  final all = await client.users.listAll();
  progress.complete();
  if (all.isEmpty) {
    log.warn('No users found.');
    return null;
  }
  final choices = <Object>[...all, pickCancel];
  final picked = log.chooseOne<Object>(
    'Select a user',
    choices: choices,
    display: (c) {
      if (c is PickCancel) return '— Cancel —';
      final u = c as User;
      return '${u.firstName ?? ''} ${u.lastName ?? ''} (${u.email ?? ''})';
    },
  );
  if (picked is PickCancel) return null;
  return picked as User;
}

Future<Task?> pickTask(
  InvoiceNinjaClient client,
  Logger log, {
  String? clientId,

  /// When true, only tasks with no `invoice_id` (not yet on an invoice).
  bool uninvoicedOnly = false,
}) async {
  final progress = log.progress(
    uninvoicedOnly ? 'Loading uninvoiced tasks' : 'Loading tasks',
  );
  var all = await client.tasks.listAll();
  progress.complete();
  if (clientId != null && clientId.isNotEmpty) {
    all = all.where((t) => t.clientId == clientId).toList();
  }

  if (uninvoicedOnly) {
    final ids = all.map((t) => t.id).where((id) => id.isNotEmpty).toList();
    final full = await Future.wait(ids.map(client.tasks.get));
    all = full.where((t) => !taskHasInvoiceId(t)).toList();
  }

  all.sort((a, b) => taskSortTime(b).compareTo(taskSortTime(a)));

  if (all.isEmpty) {
    log.warn(uninvoicedOnly ? 'No uninvoiced tasks found.' : 'No tasks found.');
    return null;
  }
  final choices = <Object>[...all, pickCancel];
  final picked = log.chooseOne<Object>(
    'Select a task',
    choices: choices,
    defaultValue: all.first,
    display: (c) => c is PickCancel ? '— Cancel —' : _taskLabel(c as Task),
  );
  if (picked is PickCancel) return null;
  return picked as Task;
}
