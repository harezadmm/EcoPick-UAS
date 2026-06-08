import 'dart:convert';
import 'dart:io';

/// Model hasil geocoding dari Nominatim (reverse maupun forward search)
class NominatimResult {
  final String displayName;
  final String road;
  final String suburb;
  final String city;
  final String postcode;
  // Koordinat — tersedia pada hasil forward search
  final double? lat;
  final double? lon;

  const NominatimResult({
    required this.displayName,
    required this.road,
    required this.suburb,
    required this.city,
    required this.postcode,
    this.lat,
    this.lon,
  });

  /// Alamat ringkas: "Jl. X, Kelurahan Y, Kota Z"
  String get shortAddress {
    final parts = <String>[];
    if (road.isNotEmpty) parts.add(road);
    if (suburb.isNotEmpty) parts.add(suburb);
    if (city.isNotEmpty) parts.add(city);
    return parts.isNotEmpty ? parts.join(', ') : displayName;
  }

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    final addr = (json['address'] as Map<String, dynamic>?) ?? {};
    return NominatimResult(
      displayName: (json['display_name'] as String?) ?? '',
      road: (addr['road'] as String?) ??
          (addr['pedestrian'] as String?) ??
          (addr['street'] as String?) ??
          '',
      suburb: (addr['suburb'] as String?) ??
          (addr['neighbourhood'] as String?) ??
          (addr['village'] as String?) ??
          (addr['county'] as String?) ??
          '',
      city: (addr['city'] as String?) ??
          (addr['town'] as String?) ??
          (addr['municipality'] as String?) ??
          '',
      postcode: (addr['postcode'] as String?) ?? '',
      lat: double.tryParse((json['lat'] as String?) ?? ''),
      lon: double.tryParse((json['lon'] as String?) ?? ''),
    );
  }
}

/// Service untuk Nominatim Geocoding (OpenStreetMap)
class NominatimService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  // Nominatim mensyaratkan User-Agent yang valid & tidak default
  static const _userAgent = 'EcoPoinApp/1.0 (flutter; surabaya)';

  // ── Reverse Geocoding ────────────────────────────────────────────────────

  /// Koordinat → alamat (reverse geocoding)
  Future<NominatimResult> reverse(double lat, double lon) async {
    final uri = Uri.parse(
      '$_baseUrl/reverse'
      '?lat=$lat&lon=$lon'
      '&format=json&addressdetails=1&zoom=18&accept-language=id',
    );
    return NominatimResult.fromJson(await _get(uri));
  }

  // ── Forward Search ───────────────────────────────────────────────────────

  /// Teks bebas → daftar tempat (forward geocoding)
  /// [countryCode] mis. "id" untuk membatasi ke Indonesia
  Future<List<NominatimResult>> search(
    String query, {
    String countryCode = 'id',
    int limit = 6,
  }) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/search'
      '?q=${Uri.encodeComponent(query.trim())}'
      '&format=json&addressdetails=1&limit=$limit'
      '&countrycodes=$countryCode'
      '&accept-language=id',
    );

    final raw = await _get(uri);
    if (raw is! List) return [];
    return (raw as List)
        .whereType<Map<String, dynamic>>()
        .map(NominatimResult.fromJson)
        .toList();
  }

  // ── Internal HTTP helper ─────────────────────────────────────────────────

  /// GET request, returns decoded JSON (Map or List)
  Future<dynamic> _get(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Nominatim HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }
}
