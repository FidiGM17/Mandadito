import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandadito/modelos/compra.dart';
import 'package:mandadito/servicios/estado_app.dart';

class PantallaLista extends StatelessWidget {
  const PantallaLista({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending = state.shoppingItems.where((e) => !e.checked).toList();
    final bought = state.shoppingItems.where((e) => e.checked).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de compras')),
      body: ListView(
        children: [
          if (pending.isNotEmpty) _SectionHeader('Por comprar (${pending.length})'),
          ...pending.map((item) => _ShoppingTile(item: item)),
          if (bought.isNotEmpty) _SectionHeader('Compradas (${bought.length})'),
          ...bought.map((item) => _ShoppingTile(item: item)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    DateTime? plannedDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Agregar producto a comprar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Producto'),
                autofocus: true,
              ),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  plannedDate == null
                      ? 'Día planeado para comprar (opcional)'
                      : DateFormat('dd/MM/yyyy').format(plannedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => plannedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                context.read<AppState>().addShoppingItem(
                      Compra(
                        name: nameCtrl.text.trim(),
                        quantity: int.tryParse(qtyCtrl.text) ?? 1,
                        dateAdded: DateTime.now(),
                        plannedDate: plannedDate,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Colors.grey[600]),
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  final Compra item;
  const _ShoppingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<AppState>().removeShoppingItem(item.id!),
      child: CheckboxListTile(
        value: item.checked,
        onChanged: (_) => context.read<AppState>().toggleShoppingChecked(item),
        title: Text(
          item.name,
          style: item.checked
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          'Cantidad: ${item.quantity}'
          '${item.plannedDate != null ? '  ·  Día: ${dateFmt.format(item.plannedDate!)}' : ''}',
        ),
      ),
    );
  }
}
