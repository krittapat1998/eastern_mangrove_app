import 'package:eastern_mangrove_app/utils/coordinates.dart';
import 'package:eastern_mangrove_app/utils/thai_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Google Maps copied coordinates', () {
    expect(parseCoordinates('12.5236, 102.0801'), {'lat': 12.5236, 'lon': 102.0801});
    expect(parseCoordinates('12.5236 102.0801'), {'lat': 12.5236, 'lon': 102.0801});
    expect(parseCoordinates('12.5236°N 102.0801°E'), {'lat': 12.5236, 'lon': 102.0801});
    expect(parseCoordinates('https://www.google.com/maps/@12.5236,102.0801,15z'),
        {'lat': 12.5236, 'lon': 102.0801});
  });
  test('fixes swapped order and rejects non-Thailand / garbage', () {
    expect(parseCoordinates('102.0801, 12.5236'), {'lat': 12.5236, 'lon': 102.0801});
    expect(parseCoordinates('51.5, -0.12'), isNull);
    expect(parseCoordinates('สวัสดี'), isNull);
    expect(parseCoordinates(''), isNull);
  });
  test('Thai year helpers', () {
    expect(ThaiDate.toBe(2026), 2569);
    expect(ThaiDate.yearFromInput('2569'), 2026);
    expect(ThaiDate.yearFromInput('2026'), 2026);
    expect(ThaiDate.yearText(2026), '2569');
    expect(ThaiDate.monthYear(11, 2026), 'พ.ย. 2569');
  });
}
