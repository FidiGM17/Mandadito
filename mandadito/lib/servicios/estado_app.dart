import 'package:flutter/foundation.dart';
import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/modelos/compra.dart';
import 'package:mandadito/servicios/servicio_bd.dart';
import 'package:mandadito/servicios/servicio_notificacion.dart';

class AppState extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _notifications = NotificationService.instance;

  List<Articulo> pantryItems = [];
  List<Compra> shoppingItems = [];

  Future<void> loadAll() async {
    pantryItems = await _db.getPantryItems(status: 'activo');
    shoppingItems = await _db.getShoppingItems();
    notifyListeners();
  }

  //DESPENSA

  Future<void> addPantryItem(Articulo item) async {
    final id = await _db.insertPantryItem(item);
    final saved = item.copyWith(id: id);
    pantryItems.add(saved);
    //Aviso de caducidad
    await _notifications.scheduleExpirationAlert(saved);
    notifyListeners();
  }

  Future<void> updatePantryItem(Articulo item) async {
    await _db.updatePantryItem(item);
    final index = pantryItems.indexWhere((e) => e.id == item.id);
    if (index != -1) pantryItems[index] = item;
    //Si se cambia la fecha de caducidad se reprograma la notificación
    await _notifications.cancelExpirationAlert(item.id!);
    await _notifications.scheduleExpirationAlert(item);
    notifyListeners();
  }

  //Descuenta una pieza de un producto
  Future<void> consumeOneUnit(Articulo item) async {
    if (item.remainingUnits == null || item.remainingUnits! <= 0) return;

    final newRemaining = item.remainingUnits! - 1;
    final shouldNotify = newRemaining <= 1 && !item.lowStockNotified;

    final updated = item.copyWith(
      remainingUnits: newRemaining,
      lowStockNotified: shouldNotify ? true : item.lowStockNotified,
    );

    await _db.updatePantryItem(updated);
    final index = pantryItems.indexWhere((e) => e.id == item.id);
    if (index != -1) pantryItems[index] = updated;

    if (shouldNotify) {
      await _notifications.notifyLowStock(updated);
    }
    notifyListeners();
  }

  //Elimina el alimento de la despensa porque se terminó o se echó a perder
  Future<void> removePantryItem(int id, {String reason = 'consumido'}) async {
    await _db.deletePantryItem(id);
    await _notifications.cancelExpirationAlert(id);
    await _notifications.cancelLowStock(id);
    pantryItems.removeWhere((e) => e.id == id);
    notifyListeners();
  }


  //LISTA DE COMPRAS

  Future<void> addShoppingItem(Compra item) async {
    final id = await _db.insertShoppingItem(item);
    shoppingItems.add(item.copyWith(id: id));
    await _refreshShoppingReminder();
    notifyListeners();
  }

  Future<void> toggleShoppingChecked(Compra item) async {
    final updated = item.copyWith(checked: !item.checked);
    await _db.updateShoppingItem(updated);
    final index = shoppingItems.indexWhere((e) => e.id == item.id);
    if (index != -1) shoppingItems[index] = updated;
    await _refreshShoppingReminder();
    notifyListeners();
  }

  Future<void> removeShoppingItem(int id) async {
    await _db.deleteShoppingItem(id);
    shoppingItems.removeWhere((e) => e.id == id);
    await _refreshShoppingReminder();
    notifyListeners();
  }

  //Reprograma el recordatorio con los productos que aún faltan por comprar
  Future<void> _refreshShoppingReminder() async {
    final pending = shoppingItems.where((e) => !e.checked).toList();
    await _notifications.cancelShoppingReminder();
    if (pending.isEmpty) return;

    final withDate = pending.where((e) => e.plannedDate != null).toList();
    if (withDate.isEmpty) return;

    withDate.sort((a, b) => a.plannedDate!.compareTo(b.plannedDate!));
    await _notifications.scheduleShoppingReminder(
      plannedDate: withDate.first.plannedDate!,
      pendingItems: pending,
    );
  }
}
