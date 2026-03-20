import 'package:diacritic/diacritic.dart';

/// Lowercase, trim, and strip accents (á → a, ñ → n, etc.) for search/compare.
String normalizeForSearch(String input) =>
    removeDiacritics(input.toLowerCase().trim());

/// Whether [haystack] contains [needle] after accent-insensitive normalization.
bool containsNormalized(String haystack, String needle) {
  if (needle.isEmpty) return true;
  return normalizeForSearch(haystack).contains(normalizeForSearch(needle));
}
