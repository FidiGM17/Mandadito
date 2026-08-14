import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/servicios/estado_app.dart';

//Formulario para el nombre, cantidad, tamaño y fecha de caducidad
class AddEditProductScreen extends StatefulWidget {
  final Articulo existingItem;
  final bool isNewFromScan;

  const AddEditProductScreen({
    super.key,
    required this.existingItem,
    this.isNewFromScan = false,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _totalUnitsCtrl;
  late DateTime _expirationDate;
  late bool _tracksUnits;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item.name);
    _quantityCtrl = TextEditingController(text: item.quantity.toString());
    _sizeCtrl = TextEditingController(text: item.contentSize);
    _expirationDate = item.expirationDate;
    _tracksUnits = item.tracksUnits;
    _totalUnitsCtrl =
        TextEditingController(text: item.totalUnits?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _sizeCtrl.dispose();
    _totalUnitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Fecha de caducidad',
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isNew = widget.existingItem.id == null;
    final totalUnits =
        _tracksUnits ? int.tryParse(_totalUnitsCtrl.text) : null;

    final item = widget.existingItem.copyWith(
      name: _nameCtrl.text.trim(),
      quantity: int.parse(_quantityCtrl.text),
      contentSize: _sizeCtrl.text.trim(),
      expirationDate: _expirationDate,
      totalUnits: _tracksUnits ? totalUnits : null,
      // Al crear el producto, empieza con todas sus piezas disponibles.
      // Al editar uno existente, se respeta lo que ya llevaba consumido
      // salvo que se acabe de activar el conteo por piezas.
      remainingUnits: !_tracksUnits
          ? null
          : (isNew || widget.existingItem.remainingUnits == null)
              ? totalUnits
              : widget.existingItem.remainingUnits,
      lowStockNotified: _tracksUnits ? widget.existingItem.lowStockNotified : false,
    );

    final state = context.read<AppState>();
    if (item.id == null) {
      await state.addPantryItem(item);
    } else {
      await state.updatePantryItem(item);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem.id != null;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.existingItem.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Image.network(widget.existingItem.imageUrl!, height: 120),
              ),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del alimento'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad comprada (unidades)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Cantidad inválida';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sizeCtrl,
              decoration: const InputDecoration(
                labelText: 'Tamaño del contenido (ej. 500 g, 1 L)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el tamaño' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Viene en paquete de varias piezas'),
              subtitle: const Text(
                'Ej. cartón de huevos, paquete de yogurts. Te avisaremos cuando quede solo 1.',
              ),
              value: _tracksUnits,
              onChanged: (v) => setState(() => _tracksUnits = v),
            ),
            if (_tracksUnits)
              TextFormField(
                controller: _totalUnitsCtrl,
                decoration: const InputDecoration(
                  labelText: '¿Cuántas piezas trae el paquete?',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (!_tracksUnits) return null;
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2) return 'Ingresa 2 o más piezas';
                  return null;
                },
              ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de caducidad'),
              subtitle: Text(dateFmt.format(_expirationDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Text(
              'La app te avisará a partir de un mes antes de esta fecha, '
              'y luego todos los días hasta que elimines el producto de tu despensa.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: Text(isEditing ? 'Guardar cambios' : 'Agregar a la despensa'),
            ),
          ],
        ),
      ),
    );
  }
}
