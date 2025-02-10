//es la pagina del producto una vez se lo aprieta en welcome

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart'; 
import 'package:url_launcher/url_launcher.dart'; // Añadir esta importación
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Asegúrate de agregar este paquete en pubspec.yaml
import './TiendaProductosPage.dart';  // Ajusta la ruta según tu estructura de archivos
import './DirectionsMapScreen.dart';
import '../api_service.dart';
import './CategoryStoresPage.dart';
import './PaymentMethodStoresPage.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> producto;
  final Map<String, dynamic> tienda;

  const ProductDetailPage({
    super.key,
    required this.producto,
    required this.tienda,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int selectedQuantity = 1;
  bool isLoading = false;

  String _formatOpeningHours(String horarioApertura, String horarioCierre) {
    try {
      // Parse time strings into TimeOfDay
      final apertura = TimeOfDay(
        hour: int.parse(horarioApertura.split(':')[0]),
        minute: int.parse(horarioApertura.split(':')[1]),
      );
      final cierre = TimeOfDay(
        hour: int.parse(horarioCierre.split(':')[0]),
        minute: int.parse(horarioCierre.split(':')[1]),
      );

      // Format times to 12-hour format
      String formatTime(TimeOfDay time) {
        final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
        final period = time.hour >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
      }

      return '${formatTime(apertura)} - ${formatTime(cierre)}';
    } catch (e) {
      return 'Horario no disponible';
    }
  }
Future<void> _cargarDatosTienda() async {
  try {
    final tiendaCompleta = await ApiService.obtenerTienda(widget.tienda['id']);
    
    setState(() {
      // Update the logo URL
      widget.tienda['logo'] = tiendaCompleta['url_logo'];
    });
  } catch (e) {
    print("Error al cargar datos de la tienda: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de la tienda')),
      );
    }
  }
}
  // Add the new _buildPromotions widget
  Widget _buildPromotions(Map<String, dynamic> producto) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Promoción NxM
        if (producto['promocion_nx'] != null && 
            producto['promocion_nx'].toString().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              producto['promocion_nx'].toString().toUpperCase(),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

        // Promoción porcentual
        if (producto['promocion_porcentaje'] != null && 
            producto['promocion_porcentaje'].toString().isNotEmpty &&
            producto['promocion_unidad'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${producto['promocion_porcentaje']}% en la ${producto['promocion_unidad']}ª unidad',
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
@override
void initState() {
  super.initState();
  _cargarDatosTienda();
}
  String _formatOpeningDays(String diasAtencion) {
    switch (diasAtencion) {
      case 'lunes_a_viernes':
        return 'Lunes a Viernes';
      case 'lunes_a_sabado':
        return 'Lunes a Sábado';
      case 'todos_los_dias':
        return 'Todos los días';
      default:
        return 'Días no especificados';
    }
  }

   // Añadir esta nueva función para manejar la apertura de WhatsApp
  void _abrirWhatsApp() async {
    final whatsapp = widget.tienda['whatsapp'];
    if (whatsapp == null || whatsapp.isEmpty) return;

    // Crear mensaje predefinido
    final mensaje = 'Hola! Me interesa el producto ${widget.producto['nombre']}';
    final urlEncoded = Uri.encodeFull(mensaje);
    
    // Crear URL de WhatsApp
    final whatsappUrl = 'https://wa.me/$whatsapp?text=$urlEncoded';
    
    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al abrir WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para normalizar texto con caracteres especiales
  String normalizeText(String text) {
    try {
      // Decodifica la cadena si está en UTF-8
      String decoded = utf8.decode(utf8.encode(text));
      
      // Reemplaza secuencias específicas que puedan haber quedado
      decoded = decoded
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã', 'Á');
        
      return decoded;
    } catch (e) {
      // Si falla la decodificación UTF-8, aplicamos reemplazos directos
      return text
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ãº', 'ú')
        .replaceAll('Ã±', 'ñ')
        .replaceAll('Ã', 'Á')
        .replaceAll('&aacute;', 'á')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&iacute;', 'í')
        .replaceAll('&oacute;', 'ó')
        .replaceAll('&uacute;', 'ú')
        .replaceAll('&ntilde;', 'ñ');
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Precio no disponible';
    try {
      final double numPrice = double.parse(price.toString());
      return '\$${numPrice.toStringAsFixed(2)}';
    } catch (e) {
      return 'Precio inválido';
    }
  }
  List<String> _parsePaymentMethods(Map<String, dynamic> tienda) {
  final paymentMethodFields = [
    "efectivo", "debito", "credito", "transferencia_bancaria",
    "pago_movil", "qr", "monedero_electronico", "criptomoneda",
    "pasarela_en_linea", "cheque", "pagos_a_plazos", "vales",
    "contra_entrega", "debito_directo", "creditos_internos"
  ];

  return paymentMethodFields.where((method) {
    return tienda[method] == true;
  }).toList();
}
String _formatPaymentMethodName(String method) {
  return method.split('_').map((word) {
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}
 Widget _buildPaymentMethodChip(String method) {
 IconData icon = _getPaymentMethodIcon(method);
 String formattedMethod = _formatPaymentMethodName(method);
 
 return GestureDetector(
   onTap: () {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => PaymentMethodStoresPage(
           paymentMethod: method,
         ),
       ),
     );
   },
   child: Chip(
     avatar: Icon(icon, size: 18),
     label: Text(
       formattedMethod,
       style: const TextStyle(fontSize: 12),
     ),
     backgroundColor: Colors.grey[200],
   ),
 );
}

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'efectivo':
        return Icons.money;
      case 'debito':
        return Icons.credit_card;
      case 'credito':
        return Icons.credit_card;
      case 'transferencia_bancaria':
        return Icons.account_balance;
      case 'pago_movil':
        return Icons.phone_android;
      case 'qr':
        return Icons.qr_code;
      case 'monedero_electronico':
        return Icons.account_balance_wallet;
      case 'criptomoneda':
        return Icons.currency_bitcoin;
      case 'pasarela_en_linea':
        return Icons.shopping_cart;
      case 'cheque':
        return Icons.note;
      case 'pagos_a_plazos':
        return Icons.calendar_today;
      case 'vales':
        return Icons.receipt;
      case 'contra_entrega':
        return Icons.local_shipping;
      case 'debito_directo':
        return Icons.account_balance;
      case 'creditos_internos':
        return Icons.store;
      default:
        return Icons.payment;
    }
  }

  void _incrementQuantity() {
    final int disponible = widget.producto['cantidad_disponible'] ?? 0;
    if (selectedQuantity < disponible) {
      setState(() {
        selectedQuantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (selectedQuantity > 1) {
      setState(() {
        selectedQuantity--;
      });
    }
  }

  Future<void> _realizarReserva() async {
    if (!AuthService.isAuthenticated()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para realizar una reserva'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/reservas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
        body: jsonEncode({
          'tienda_id': widget.tienda['id'],
          'productos_ids': [widget.producto['id']],
          'cantidades': [selectedQuantity],
        }),
      );

      if (response.statusCode == 201) {
        // Actualizar el estado de la página
        setState(() {
          final newDisponible = (widget.producto['cantidad_disponible'] ?? 0) - selectedQuantity;
          widget.producto['cantidad_disponible'] = newDisponible;
          selectedQuantity = 1;
        });

        // Mostrar notificación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Producto reservado. Ve a mis reservas para más detalles.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al realizar la reserva');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
@override
Widget build(BuildContext context) {
  bool esServicio = widget.producto['es_servicio'] ?? false;
  final int cantidadDisponible = widget.producto['cantidad_disponible'] ?? 0;
  final List<dynamic> metodosPago = (widget.tienda['metodos_pago'] as List<dynamic>?)
      ?.map((metodo) => metodo['nombre'].toString())
      .toList() ?? [];
  print('Datos de la tienda: ${widget.tienda}');
  
  return WillPopScope(
  onWillPop: () async {
    Navigator.pushReplacementNamed(context, '/welcome'); // para recargar el welcome page
    return false;
  },
  child: Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/welcome');
        },
      ),
      title: Text(normalizeText(widget.producto['nombre'] ?? 'Detalle del Producto')),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Center(
              child: Image.network(
                widget.producto['url_imagen'] ?? '',
                height: 200,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Información del producto
            Text(
              normalizeText(widget.producto['nombre'] ?? 'Sin nombre'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.producto['promocion_nx']?.toString().isNotEmpty == true ||
                widget.producto['promocion_porcentaje']?.toString().isNotEmpty == true) ...[
              const Text(
                'Promociones Activas:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPromotions(widget.producto),
              const SizedBox(height: 16),
            ],
            Text(
              'Descripción: ${normalizeText(widget.producto['descripcion'] ?? 'No disponible')}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Precio: ${_formatPrice(widget.producto['precio'])}',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.producto['precio_original'] != null &&
                (double.tryParse(widget.producto['precio'].toString()) ?? 0) <
                    (double.tryParse(widget.producto['precio_original'].toString()) ?? 0))
              Text(
                'Precio original: ${_formatPrice(widget.producto['precio_original'])}',
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 16),

            // Información de servicio o disponibilidad
            if (esServicio) ...[
              const Text(
                'Servicio',
                style: TextStyle(fontSize: 16),
              ),
            ] else if (widget.producto['permite_reservas']) ...[
              Text(
                'Cantidad disponible: $cantidadDisponible',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),

            // Información de la tienda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Logo display with new implementation
                      if (widget.tienda['logo'] != null) 
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(widget.tienda['logo']),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) => const DecorationImage(
                                image: AssetImage('assets/default_store_icon.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.store, 
                            size: 50, 
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          normalizeText(widget.tienda['nombre'] ?? 'Sin nombre'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                 GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryStoresPage(
          categoria: normalizeText(widget.tienda['categoria'] ?? 'No especificada'),
        ),
      ),
    );
  },
  child: Text(
    'Categoría: ${normalizeText(widget.tienda['categoria'] ?? 'No especificada')}',
    style: const TextStyle(
      fontSize: 16, 
      color: Colors.blue, 
      decoration: TextDecoration.underline
    ),
  ),
),
                  Text(
                    'Dirección: ${normalizeText(widget.tienda['direccion_calle'] ?? '')} ${widget.tienda['direccion_numero'] ?? ''}, ${normalizeText(widget.tienda['ciudad'] ?? '')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 8),
                  // Horarios de atención
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatOpeningDays(widget.tienda['dias_atencion'] ?? ''),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              _formatOpeningHours(
                                widget.tienda['horario_apertura'] ?? '',
                                widget.tienda['horario_cierre'] ?? '',
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TiendaProductosPage(
                              tienda: widget.tienda,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.store),
                      label: const Text('Ver más productos de esta tienda'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.tienda['coordenada_latitud'] != null && 
                      widget.tienda['coordenada_longitud'] != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectionsMapScreen(
                                storeName: widget.tienda['nombre'] ?? 'Tienda',
                                destinationLat: widget.tienda['coordenada_latitud'],
                                destinationLng: widget.tienda['coordenada_longitud'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Ver cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Botón de WhatsApp
            if (widget.tienda['whatsapp'] != null && widget.tienda['whatsapp'].isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _abrirWhatsApp,
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                  label: const Text('Contactar por WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // Métodos de pago
            const SizedBox(height: 16),
            if (widget.tienda.isNotEmpty) ...[
              const Text(
                'Métodos de Pago Aceptados:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _parsePaymentMethods(widget.tienda)
                    .map<Widget>((metodo) => _buildPaymentMethodChip(metodo))
                    .toList(),
              ),
            ],

            // Disponibilidad
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Disponibilidad: ',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  (widget.producto['disponibilidad'] ?? false) ? 'Disponible' : 'No disponible',
                  style: TextStyle(
                    fontSize: 16,
                    color: (widget.producto['disponibilidad'] ?? false) ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Controles de reserva
            if (!esServicio) ...[
              const SizedBox(height: 16),
              if (!widget.producto['permite_reservas']) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'No se permiten reservas',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (cantidadDisponible > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _decrementQuantity,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        selectedQuantity.toString(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: _incrementQuantity,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || !(widget.producto['disponibilidad'] ?? false)
                          ? null
                          : _realizarReserva,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text('Reservar $selectedQuantity ${selectedQuantity == 1 ? 'unidad' : 'unidades'}'),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    ),
  ),
  );
}
}