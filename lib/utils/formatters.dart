String safeString(dynamic value, [String fallback = '—']) => value == null ? fallback : value.toString();
String number(dynamic value) {
  if (value is num) return value.toString();
  return safeString(value);
}
String cardImage(dynamic card) {
  if (card is Map && card['iconUrls'] is Map) return (card['iconUrls']['medium'] ?? card['iconUrls']['evolution'])?.toString() ?? '';
  return '';
}
int cardElixir(dynamic card) => card is Map && card['elixirCost'] is num ? (card['elixirCost'] as num).round() : 0;
String rarity(dynamic card) => safeString(card is Map ? card['rarity'] : null, 'Unknown');
