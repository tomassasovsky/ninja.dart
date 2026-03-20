# Invoicing Ninja

Dart tooling for **[Invoice Ninja](https://www.invoiceninja.com/)**: a terminal-first **interactive CLI** (`ninja`) and a small reusable HTTP package — [`invoice_ninja_client`](packages/invoice_ninja_client/) — over the `/api/v1` REST API.

---

## Quick start

```bash
cd invoicing-ninja   # your clone
dart pub get

export INVOICE_NINJA_BASE_URL='https://invoice.example.com'
export INVOICE_NINJA_API_TOKEN='your-api-token'

# Interactive menus (clients, projects, tasks, invoicing flows)
dart run bin/ninja.dart
```

Prefer saved tenants instead of env vars? See [Configuration](#configuration).

---

## What’s in the repo

| | |
| --- | --- |
| **[`invoice_ninja_client`](packages/invoice_ninja_client/)** | Typed models (`Client`, `Task`, `Invoice`, …), resource APIs, retries, pagination |
| **[`lib/`](lib/)** | Shared ops, [profiles](lib/profile_store.dart) + [OS-backed tokens](lib/secure_token.dart), [interactive CLI](lib/interactive/cli.dart) and [flows](lib/interactive/flows/), date/time helpers, optional JSONL logging |
| **[`bin/ninja.dart`](bin/ninja.dart)** | Interactive CLI entrypoint |

Static analysis uses [`very_good_analysis`](https://pub.dev/packages/very_good_analysis).

---

## Configuration

### Environment

| Variable | Meaning |
| --- | --- |
| `INVOICE_NINJA_BASE_URL` | Instance origin only, e.g. `https://invoice.example.com` (no `/api/v1` suffix) |
| `INVOICE_NINJA_API_TOKEN` | API token from Invoice Ninja |

### CLI overrides

| Flag | Short |
| --- | --- |
| `--base-url` | `-b` |
| `--token` | `-t` |

**Precedence (per field):** CLI flags → `--profile` / `-p` (if set) → default saved profile → environment variables.

Saved profiles **override** env vars when the profile supplies that field—so an old token left in your shell does not mask the keychain. To rely on env only, unset them or pass `--token` / `--base-url` explicitly.

### Saved profiles (multiple tenants)

**Tokens are not stored in `profiles.json`.** They go in the OS secure store:

- **macOS:** Keychain (generic password; service `dev.invoicing-ninja.cli`)
- **Linux:** [libsecret](https://wiki.gnome.org/Projects/Libsecret) via `secret-tool` (e.g. `libsecret-tools`)
- **Windows:** Credential Manager (via [`win32`](https://pub.dev/packages/win32))

`profiles.json` holds profile names, default profile, and base URLs (schema **v2**). A legacy **v1** file with plaintext `apiToken` is migrated on first load: tokens move into the OS store and are removed from disk.

**Config directory**

- macOS / Linux: `$XDG_CONFIG_HOME/invoicing-ninja/` or `~/.config/invoicing-ninja/`
- Windows: `%APPDATA%\invoicing-ninja\`

On Unix, `profiles.json` is chmod **600** after writes. Do not commit files from this directory.

### Profile flags

| Flag | Behavior |
| --- | --- |
| `--save-profile NAME` | Save base URL + token from flags/env as `NAME`, set as default, exit |
| `--list-profiles` | List profiles (masked token hint), exit |
| `--delete-profile NAME` | Remove a profile, exit |
| `--profile NAME` / `-p NAME` | Use that profile for missing fields (flags still win) |
| *(none)* | Default saved profile fills missing URL/token before env |

```bash
dart run bin/ninja.dart --save-profile client-a \
  -b https://invoice-a.example.com -t YOUR_TOKEN

dart run bin/ninja.dart
```

In the interactive CLI, use **Manage saved profiles** to add, change default, or remove profiles.

**HTTP 403 “Invalid token”** with a saved profile: `unset INVOICE_NINJA_API_TOKEN`, check `ninja --list-profiles`, re-save the profile if the keychain entry is wrong.

---

## Interactive CLI (`ninja`)

Built with [`mason_logger`](https://pub.dev/packages/mason_logger): spinners while data loads, arrow-key menus (`↑`/`↓` or `j`/`k`, Enter). Use a real TTY, not a pipe.

```bash
dart run bin/ninja.dart
```

You pick **clients, projects, users, and tasks** from lists (no raw IDs). New tasks default their description from the **most recently updated task on the same project**. **Date ranges** use the latest invoice with task lines for that client: calendar coverage from `time_log`, default start = next **weekday** after that span (clamped to today if needed), default end = **today**. Rate and hours default from that invoice (rate from the first task line; hours from the **earliest** `time_log` segment, local time).

### Shell completion

[`cli_completion`](https://pub.dev/packages/cli_completion): first interactive run may install bash/zsh completion snippets. Or run explicitly:

```bash
ninja install-completion-files
# …
ninja uninstall-completion-files
```

Restart the shell after installing.

### Global `ninja` vs `dart run`

After `dart pub global activate --source path .`, the `ninja` shim may run `pub get` and recompile often. While hacking on this repo, prefer:

```bash
dart run bin/ninja.dart
```

### Install a native binary

Defaults to `~/.local/bin/ninja`:

```bash
chmod +x scripts/install_ninja.sh
./scripts/install_ninja.sh
```

Override: `INSTALL_DIR=/usr/local/bin ./scripts/install_ninja.sh` (may need `sudo`).

Manual: `dart compile exe bin/ninja.dart -o build/ninja && cp build/ninja ~/.local/bin/`

### Invoicing from a task

The UI and API share the same backend: an invoice whose `line_items` reference the task (`task_id`, line `type_id`, etc.). Payloads differ by Invoice Ninja version. If you need to inspect a real payload, create one invoice in the web UI, then:

```http
GET /api/v1/invoices/{id}
```

and use `data.line_items[]` as a template.

**Line layout** (Service vs Description columns) is documented in [`format`](format); implementation lives in [`lib/invoice_line_notes.dart`](lib/invoice_line_notes.dart). The interactive flow lists **uninvoiced** tasks only (each task is refetched with `GET /tasks/{id}` so `invoice_id` / `invoiced` match the server). Tasks sort **newest first** with the latest preselected; already-invoiced tasks are excluded.

**Due date:** draft invoices get `date` (default today) and `due_date`. If you don’t override due date, the offset `due_date − date` from the client’s **latest** invoice is reused; the flow prompts with that as the default.

**After creating a draft:** the CLI prints a **review** (amount, dates, lines, invitations) and can call **`POST /api/v1/invoices/bulk`** with `action: email` (one email per invitation). For ad-hoc addresses, use portal links or the web UI.

---

## Using `invoice_ninja_client` in Dart

Resource methods return **typed models**, not raw `Map` JSON:

```dart
import 'package:invoice_ninja_client/invoice_ninja_client.dart';

final client = InvoiceNinjaClient(
  config: InvoiceNinjaConfig(
    baseUri: Uri.parse('https://invoice.example.com'),
    apiToken: 'token',
  ),
);
try {
  final created = await client.clients.create({
    'name': 'Acme',
    'contacts': [<String, dynamic>{}],
  });
  print('${created.id}  ${created.number}');
  final tasks = await client.tasks.listAll();
  for (final t in tasks) {
    print(t.description);
  }
} finally {
  client.close();
}
```

See [`packages/invoice_ninja_client/README.md`](packages/invoice_ninja_client/README.md) for package-level details.

---

## Tests

```bash
dart test
( cd packages/invoice_ninja_client && dart test )
```

---

## Security note

Do not commit API tokens or `profiles.json` from your machine. Use env vars, your shell profile, or a local `.env` loaded by your environment—not the repo.
