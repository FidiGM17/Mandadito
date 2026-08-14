import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/servicios/estado_app.dart';
import 'package:mandadito/pantallas/pantalla_editarProduc.dart';
import 'package:mandadito/pantallas/pantalla_escaner.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = [...state.pantryItems]
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi despensa')),
      body: items.isEmpty
          ? const Center(child: Text('Aún no hay productos. Escanea uno para empezar.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => _PantryTile(item: items[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PantallaEscaner()),
        ),
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  final Articulo item;
  const _PantryTile({required this.item});

  Color _statusColor() {
    final days = item.daysUntilExpiration;
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.orange;
    if (days <= 30) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final reason = direction == DismissDirection.startToEnd
            ? 'consumido'
            : 'caducado/echado a perder';
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Quitar de la despensa'),
                content: Text('¿Marcar "${item.name}" como $reason y eliminarlo?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        final reason =
            direction == DismissDirection.startToEnd ? 'consumido' : 'caducado';
        context.read<AppState>().removePantryItem(item.id!, reason: reason);
      },
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _statusColor(), radius: 8),
        title: Text(item.name),
        subtitle: Text(
          item.tracksUnits
              ? '${item.remainingUnits}/${item.totalUnits} piezas · Caduca: ${dateFmt.format(item.expirationDate)}'
              : '${item.quantity} x ${item.contentSize}  ·  Caduca: ${dateFmt.format(item.expirationDate)}',
          style: TextStyle(
            color: item.isLowStock ? Colors.deepOrange : null,
            fontWeight: item.isLowStock ? FontWeight.bold : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.isExpired
                  ? 'Caducado'
                  : 'Faltan ${item.daysUntilExpiration} días',
              style:
                  TextStyle(color: _statusColor(), fontWeight: FontWeight.bold),
            ),
            if (item.tracksUnits && (item.remainingUnits ?? 0) > 0)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Consumir 1 pieza',
                onPressed: () => context.read<AppState>().consumeOneUnit(item),
              ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditProductScreen(existingItem: item),
          ),
        ),
      ),
    );
  }
}
