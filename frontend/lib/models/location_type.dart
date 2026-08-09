class LocationType {
  static const String sector = 'sektor';
  static const String rack = 'regal';
  static const String shelf = 'polka';

  static String label(String? type) {
    if (type == sector) return 'Sektor';
    if (type == rack) return 'Regał';
    if (type == shelf) return 'Półka';
    return type ?? '-';
  }
}