class BatchStatus {
  static const String inStock = 'in_stock';
  static const String inProduction = 'in_production';
  static const String reserved = 'reserved';
  static const String missing = 'missing';
  static const String damaged = 'damaged';

  static const List<String> values = [
    inStock,
    inProduction,
    reserved,
    missing,
    damaged,
  ];

  static String label(String status) {
    switch (status) {
      case inStock:
        return 'Na magazynie';
      case inProduction:
        return 'Na produkcji';
      case reserved:
        return 'Zarezerwowany';
      case missing:
        return 'Brak';
      case damaged:
        return 'Uszkodzony';
      default:
        return status;
    }
  }
}