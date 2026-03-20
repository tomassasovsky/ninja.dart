/// @docImport 'package:mason_logger/mason_logger.dart';
library;

/// Sentinel for interactive pickers (Cancel row).
final class PickCancel {
  const PickCancel._();
}

/// Use as the last choice in [Logger.chooseOne] lists.
const PickCancel pickCancel = PickCancel._();
