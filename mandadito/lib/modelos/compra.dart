//Modelo de un artículo por comprar en la lista de la despensa
class Compra{
  final int? id;
  final String name;
  final int quantity;
  final DateTime dateAdded;
  final DateTime? plannedDate; //día en que se planea ir a comprar
  final bool checked; //si ya se palomeó la compra

  Compra({
    this.id,
    required this.name,
    required this.quantity,
    required this.dateAdded,
    this.plannedDate,
    this.checked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'dateAdded': dateAdded.toIso8601String(),
      'plannedDate': plannedDate?.toIso8601String(),
      'checked': checked ? 1 : 0,
    };
  }

  factory Compra.fromMap(Map<String, dynamic> map) {
    return Compra(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      plannedDate: map['plannedDate'] != null
          ? DateTime.parse(map['plannedDate'] as String)
          : null,
      checked: (map['checked'] as int) == 1,
    );
  }

  Compra copyWith({
    int? id,
    String? name,
    int? quantity,
    DateTime? dateAdded,
    DateTime? plannedDate,
    bool? checked,
  }) {
    return Compra(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      dateAdded: dateAdded ?? this.dateAdded,
      plannedDate: plannedDate ?? this.plannedDate,
      checked: checked ?? this.checked,
    );
  }
}
