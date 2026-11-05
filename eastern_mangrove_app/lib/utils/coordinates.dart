/// Parses coordinates copied from Google Maps.
///
/// Accepts "12.5236, 102.0801", "12.5236 102.0801", "12.5236°N 102.0801°E",
/// or a Google Maps link containing "@lat,lng" / "q=lat,lng".
/// Only points inside Thailand are accepted (catches typos); a swapped
/// "lng, lat" pair is corrected. Returns {'lat':..., 'lon':...} or null.
Map<String, double>? parseCoordinates(String text) {
  bool inThailand(double lat, double lon) =>
      lat >= 5.5 && lat <= 20.6 && lon >= 97.3 && lon <= 105.7;

  final cleaned = text.replaceAll(RegExp(r'[°NE]'), ' ');
  final pair = RegExp(r'(-?\d{1,3}\.\d+|-?\d{1,3})\s*[,\s]\s*(-?\d{1,3}\.\d+|-?\d{1,3})');
  for (final m in pair.allMatches(cleaned)) {
    final a = double.tryParse(m.group(1)!);
    final b = double.tryParse(m.group(2)!);
    if (a == null || b == null) continue;
    if (inThailand(a, b)) return {'lat': a, 'lon': b};
    if (inThailand(b, a)) return {'lat': b, 'lon': a};
  }
  return null;
}
