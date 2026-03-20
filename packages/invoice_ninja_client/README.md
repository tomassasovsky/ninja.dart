# invoice_ninja_client

HTTP client for the [Invoice Ninja](https://www.invoiceninja.com/) **`/api/v1`** REST API: retries, pagination, and **immutable models** with `fromJson`.

## Features

- **Resources:** `clients`, `projects`, `users`, `tasks`, `invoices`
- **Models:** `Client`, `Project`, `User`, `Task`, `Invoice`, `InvoiceLineItem`, and related types
- **Task** exposes `List<TimeLogEntry> timeLog` and `DateTime?` timestamps; **Invoice** uses `DateTime?` for `date`, `dueDate`, and instants
- **Helpers:** `parseApiInstant`, `parseApiCalendarDate`, `parseTimeLogRaw`, `timeLogEntryToSecondPairs`
- Request bodies stay `Map<String, dynamic>` where the API expects arbitrary JSON

## Install

This package is consumed via path/git from the parent repo (not published to pub.dev by default):

```yaml
dependencies:
  invoice_ninja_client:
    path: packages/invoice_ninja_client
```

## Usage

```dart
import 'package:invoice_ninja_client/invoice_ninja_client.dart';
```

```dart
final api = InvoiceNinjaClient(
  config: InvoiceNinjaConfig(
    baseUri: Uri.parse('https://invoice.example.com'),
    apiToken: 'your-token',
  ),
);
try {
  final client = await api.clients.create({'name': 'Acme', 'contacts': []});
  // …
} finally {
  api.close();
}
```

Environment variables and multi-tenant **profiles** are handled by the interactive **`ninja`** CLI in the repo root—see the [root README](../../README.md).

## Development

```bash
cd packages/invoice_ninja_client
dart pub get
dart test
dart analyze
```

Analysis uses [`very_good_analysis`](https://pub.dev/packages/very_good_analysis) (see [`analysis_options.yaml`](analysis_options.yaml)).
