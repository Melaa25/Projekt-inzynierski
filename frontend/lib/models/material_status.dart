class MaterialStatus {
  static const String inStock = 'in_stock';
  static const String cutting = 'cutting';
  static const String reserved = 'reserved';
  static const String issued = 'issued';
  static const String damaged = 'damaged';
  static const String missing = 'missing';
  static const String transit = 'transit';

  static const List<String> values = [
    inStock,
    cutting,
    reserved,
    issued,
    damaged,
    missing,
    transit,
  ];

  static String label(String status) {
    switch (status) {
      case inStock:
        return 'Na magazynie';
      case cutting:
        return 'Na cięciu';
      case reserved:
        return 'Zarezerwowany';
      case issued:
        return 'Wydany';
      case damaged:
        return 'Uszkodzony';
      case missing:
        return 'Brakujący';
      case transit:
        return 'W ruchu';
      default:
        return status;
    }
  }
}