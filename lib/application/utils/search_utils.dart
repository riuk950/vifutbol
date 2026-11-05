library;

/// Pure utility functions for case-insensitive and diacritics-insensitive search matching.

/// Normalizes a given string by trimming whitespace, converting to lowercase,
/// and stripping common Spanish diacritical marks (accents, tildes, umlauts).
String normalizeSearchText(String input) {
  var text = input.trim().toLowerCase();
  if (text.isEmpty) return text;

  const withAccents = 'áéíóúüñ';
  const withoutAccents = 'aeiouun';

  for (int i = 0; i < withAccents.length; i++) {
    text = text.replaceAll(withAccents[i], withoutAccents[i]);
  }

  return text;
}

/// Evaluates if [target] contains [query] after applying [normalizeSearchText]
/// to both strings. Returns `true` if [query] is empty.
bool matchesSearchQuery(String target, String query) {
  final normalizedQuery = normalizeSearchText(query);
  if (normalizedQuery.isEmpty) return true;
  final normalizedTarget = normalizeSearchText(target);
  return normalizedTarget.contains(normalizedQuery);
}
