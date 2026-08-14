import 'dart:convert';
import 'package:http/http.dart' as http;

//Resultado de la búsqueda de un producto por código de barras
class ProductInfo {
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? defaultSize;

  ProductInfo({
    required this.name,
    this.brand,
    this.imageUrl,
    this.defaultSize,
  });
}

//Consulta la API de Open Food Facts para autocompletar
//el nombre, marca, imagen y tamaño del producto a partir del código de barras


//NOTAS de seguridad y/o privacidad
//Solo se envía el número de código de barras, nunca datos personales
//Es una consulta de solo lectura (GET), no requiere ni expone API keys
//El tráfico va por HTTPS.
//Se valida el formato del código antes de armar la URL
//Se cachea en memoria por sesión para no repetir consultas
class BarcodeLookupService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  //Los códigos de barras de alimentos son de entre 8 y 14 nums
  static final RegExp _validBarcode = RegExp(r'^\d{8,14}$');

  final Map<String, ProductInfo?> _cache = {};

  Future<ProductInfo?> lookup(String barcode) async {
    final clean = barcode.trim();
    if (!_validBarcode.hasMatch(clean)) {
      //Si es un formato raro no se manda nada a la red
      return null;
    }

    if (_cache.containsKey(clean)) {
      return _cache[clean];
    }

    final uri = Uri.parse('$_baseUrl/$clean.json');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        _cache[clean] = null;
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) {
        _cache[clean] = null;
        return null; //producto no encontrado
      }

      final product = data['product'] as Map<String, dynamic>;
      final info = ProductInfo(
        name: product['product_name'] as String? ?? 'Producto sin nombre',
        brand: product['brands'] as String?,
        imageUrl: product['image_front_url'] as String?,
        defaultSize: product['quantity'] as String?,
      );
      _cache[clean] = info;
      return info;
    } catch (_) {
      //No se registra el código de barras para no exponer hábitos del usuario
      return null;
    }
  }
}
