import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/pantallas/pantalla_editarProduc.dart';
import 'package:mandadito/servicios/buscar_codigo.dart';

//Pantalla que abre la cámara y detecta el código de barras
//Busca el producto en la api de Open Food Facts
class PantallaEscaner extends StatefulWidget {
  const PantallaEscaner({super.key});

  @override
  State<PantallaEscaner> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<PantallaEscaner> {
  final MobileScannerController _controller = MobileScannerController();
  final _lookupService = BarcodeLookupService();
  bool _handled = false; // evita procesar el mismo código varias veces

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    _handled = true;
    await _controller.stop();

    final info = await _lookupService.lookup(barcode);

    if (!mounted) return;

    final draft = Articulo(
      barcode: barcode,
      name: info?.name ?? '',
      brand: info?.brand,
      imageUrl: info?.imageUrl,
      quantity: 1,
      contentSize: info?.defaultSize ?? '',
      purchaseDate: DateTime.now(),
      expirationDate: DateTime.now().add(const Duration(days: 30)),
    );

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(existingItem: draft, isNewFromScan: true),
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      Navigator.of(context).pop();
    } else {
      _handled = false;
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear producto')),
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}
