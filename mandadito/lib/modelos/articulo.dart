//Modelo de un alimento/producto
class Articulo{
  final int? id;
  final String barcode; //código de barras escaneado
  final String name; //nombre del alimento
  final String? brand; //marca que se puede consultar con la API
  final String? imageUrl; //imagen del producto
  final int quantity; //cuántas unidades se compraron
  final String contentSize; //tamaño del contenido
  final DateTime purchaseDate; //fecha de compra
  final DateTime expirationDate; //fecha de caducidad ingresada por el usuario
  final String status; //son 3: activo, consumido y caducado
  final int? totalUnits; //piezas que trae originalmente el paquete
  final int? remainingUnits; //piezas que quedan actualmente
  final bool lowStockNotified; //evita repetir la alerta de "ya casi se acaba"

  Articulo({
    this.id,
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.quantity,
    required this.contentSize,
    required this.purchaseDate,
    required this.expirationDate,
    this.status = 'activo',
    this.totalUnits,
    this.remainingUnits,
    this.lowStockNotified = false,
  });

  //Días restantes antes de que caduque
  int get daysUntilExpiration =>
      expirationDate.difference(DateTime.now()).inDays;

  bool get isExpired => daysUntilExpiration < 0;

  //Es true si el producto se maneja por piezas
  bool get tracksUnits => totalUnits != null && totalUnits! > 1;

  //Es true cuando ya solo queda 1 pieza del paquete
  bool get isLowStock =>
      tracksUnits && remainingUnits != null && remainingUnits! <= 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'contentSize': contentSize,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'status': status,
      'totalUnits': totalUnits,
      'remainingUnits': remainingUnits,
      'lowStockNotified': lowStockNotified ? 1 : 0,
    };
  }

  factory Articulo.fromMap(Map<String, dynamic> map) {
    return Articulo(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      imageUrl: map['imageUrl'] as String?,
      quantity: map['quantity'] as int,
      contentSize: map['contentSize'] as String,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      expirationDate: DateTime.parse(map['expirationDate'] as String),
      status: map['status'] as String? ?? 'activo',
      totalUnits: map['totalUnits'] as int?,
      remainingUnits: map['remainingUnits'] as int?,
      lowStockNotified: (map['lowStockNotified'] as int? ?? 0) == 1,
    );
  }

  Articulo copyWith({
    int? id,
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    int? quantity,
    String? contentSize,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? status,
    int? totalUnits,
    int? remainingUnits,
    bool? lowStockNotified,
  }) {
    return Articulo(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      contentSize: contentSize ?? this.contentSize,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      totalUnits: totalUnits ?? this.totalUnits,
      remainingUnits: remainingUnits ?? this.remainingUnits,
      lowStockNotified: lowStockNotified ?? this.lowStockNotified,
    );
  }
}
