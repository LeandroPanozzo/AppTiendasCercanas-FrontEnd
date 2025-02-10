import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({Key? key}) : super(key: key);

  @override
  _MisReservasScreenState createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  Map<String, Map<String, List<dynamic>>> reservasPorFechaYTienda = {};
  Map<String, Map<String, List<dynamic>>> reservasFiltradas = {};
  bool isLoading = true;
  String? error;
  final formatoMoneda = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  
  // Variables para paginación
  int itemsPorPagina = 10;
  int paginaActual = 0;
  bool hayMasReservas = true;
  List<String> todasLasFechas = [];

   // Controllers y variables para los filtros
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String _searchQuery = '';

  double getPrice(dynamic price) {
    if (price == null) return 0.0;
    try {
      if (price is num) return price.toDouble();
      return double.parse(price.toString());
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildPromotions(dynamic producto) {
    return Wrap(
      spacing: 8,
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
              ),
            ),
          ),

        // Promoción porcentual
        if (producto['promocion_porcentaje'] != null && 
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
              ),
            ),
          ),
      ],
    );
  }


  String getEstadoReserva(dynamic estado) {
    return estado?.toString()?.toLowerCase() ?? 'pendiente';
  }

  String getNombreProducto(dynamic producto) {
    return producto?['nombre']?.toString() ?? 'Producto sin nombre';
  }

  int getCantidadProducto(dynamic reservaProducto) {
    return int.tryParse(reservaProducto?['cantidad']?.toString() ?? '0') ?? 0;
  }

  int getProductoId(dynamic reservaProducto) {
    return int.tryParse(reservaProducto?['producto']?.toString() ?? '0') ?? 0;
  }

   @override
  void initState() {
    super.initState();
    cargarReservas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
   void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _aplicarFiltros();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
  try {
    final DateTime now = DateTime.now();
    final DateTime lastDate = DateTime(now.year + 1, now.month, now.day); // Un año desde hoy
    
    final DateTime initialDate = _selectedDate ?? now;
    final DateTime adjustedInitialDate = initialDate.isAfter(lastDate) 
        ? lastDate 
        : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: adjustedInitialDate,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _aplicarFiltros();
      });
    }
  } catch (e) {
    print('Error al mostrar el selector de fecha: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al abrir el selector de fecha'),
      ),
    );
  }
}

  void _limpiarFiltros() {
    setState(() {
      _selectedDate = null;
      _searchController.clear();
      _searchQuery = '';
      reservasFiltradas = Map.from(reservasPorFechaYTienda);
    });
  }

  void _aplicarFiltros() {
    setState(() {
      reservasFiltradas = {};
      
      reservasPorFechaYTienda.forEach((fecha, tiendasMap) {
        // Filtrar por fecha si hay una fecha seleccionada
        if (_selectedDate != null) {
          final fechaReserva = DateFormat('dd/MM/yyyy').parse(fecha);
          if (fechaReserva != _selectedDate) return;
        }

        // Filtrar por nombre de tienda si hay una búsqueda
        if (_searchQuery.isNotEmpty) {
          final tiendasFiltradas = Map.fromEntries(
            tiendasMap.entries.where((tiendaEntry) {
              return tiendaEntry.key.toLowerCase().contains(_searchQuery);
            }),
          );

          if (tiendasFiltradas.isNotEmpty) {
            reservasFiltradas[fecha] = tiendasFiltradas;
          }
        } else {
          reservasFiltradas[fecha] = tiendasMap;
        }
      });
    });
  }

   // Modificar el método cargarReservas para inicializar también las reservas filtradas
  Future<void> cargarReservas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        setState(() {
          error = 'No se encontró token de autenticación';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/reservas/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> todasLasReservas = json.decode(response.body);
        
        Map<String, Map<String, List<dynamic>>> agrupadas = {};
        
        for (var reserva in todasLasReservas) {
          try {
            final fechaReserva = reserva['fecha_reserva']?.toString();
            if (fechaReserva == null) continue;

            final fecha = DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(fechaReserva));
                
            final tiendaNombre = reserva['tienda']?['nombre']?.toString() ?? 'Tienda sin nombre';
            final tiendaId = reserva['tienda']?['id']?.toString() ?? '0';
            final tiendaKey = '$tiendaNombre (ID: $tiendaId)';

            agrupadas.putIfAbsent(fecha, () => {});
            agrupadas[fecha]!.putIfAbsent(tiendaKey, () => []);
            agrupadas[fecha]![tiendaKey]!.add(reserva);
          } catch (e) {
            print('Error procesando reserva: $e');
            continue;
          }
        }

        setState(() {
          reservasPorFechaYTienda = agrupadas;
          reservasFiltradas = Map.from(agrupadas);
          todasLasFechas = agrupadas.keys.toList()
            ..sort((a, b) {
              final dateA = DateFormat('dd/MM/yyyy').parse(a);
              final dateB = DateFormat('dd/MM/yyyy').parse(b);
              return dateB.compareTo(dateA);
            });
          isLoading = false;
          hayMasReservas = todasLasFechas.length > itemsPorPagina;
        });
      } else {
        setState(() {
          error = 'Error al cargar las reservas';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  void cargarMasReservas() {
    setState(() {
      paginaActual++;
      hayMasReservas = (paginaActual + 1) * itemsPorPagina < todasLasFechas.length;
    });
  }
  String getDiasRestantes(String fechaReserva) {
  final fecha = DateTime.parse(fechaReserva);
  final fechaLimite = fecha.add(const Duration(days: 7));
  final diasRestantes = fechaLimite.difference(DateTime.now()).inDays;
  
  if (diasRestantes <= 0) {
    return "La reserva está por vencerse hoy";
  } else if (diasRestantes == 1) {
    return "Te queda 1 día para retirar tu reserva";
  } else {
    return "Te quedan $diasRestantes días para retirar tu reserva";
  }
}

  Future<void> cancelarReserva(int reservaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No hay token de autenticación')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/reservas/$reservaId/cancelar/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada exitosamente')),
        );
        cargarReservas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar la reserva: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildEstadoChip(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getEstadoColor(estado).withOpacity(0.1),
        border: Border.all(color: getEstadoColor(estado)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: getEstadoColor(estado),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Mis Reservas'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre de tienda...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              // Fila con selector de fecha y botón para limpiar filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate == null
                              ? 'Seleccionar fecha'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar filtros'),
                      onPressed: _limpiarFiltros,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: cargarReservas,
        child: _buildBody(),
      ),
      ),
    );
  }
  @override
Widget _buildBody() {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (error != null) {
    return Center(child: Text(error!));
  }

  if (reservasFiltradas.isEmpty) {
    return const Center(
      child: Text('No se encontraron reservas con los filtros seleccionados'),
    );
  }

  // Ordenar las fechas de más reciente a más antigua
  final fechasOrdenadas = reservasFiltradas.keys.toList()
    ..sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a);
      final dateB = DateFormat('dd/MM/yyyy').parse(b);
      return dateB.compareTo(dateA);
    });

  // Aplicar paginación
  final fechasPaginadas = fechasOrdenadas
    .skip(paginaActual * itemsPorPagina)
    .take(itemsPorPagina)
    .toList();

  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          itemCount: fechasPaginadas.length,
          itemBuilder: (context, fechaIndex) {
            final fecha = fechasPaginadas[fechaIndex];
            final tiendasPorFecha = reservasFiltradas[fecha]!;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(
                  'Reservas del $fecha',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${tiendasPorFecha.length} tiendas'),
                children: tiendasPorFecha.entries.map((tiendaEntry) {
                  double totalTienda = 0;
                  for (var reserva in tiendaEntry.value) {
                    final reservaProductos = reserva['reserva_productos'] as List? ?? [];
                    final productos = reserva['productos'] as List? ?? [];
                    
                    for (var rp in reservaProductos) {
                      final productoId = getProductoId(rp);
                      final producto = productos.firstWhere(
                        (p) => p['id'] == productoId,
                        orElse: () => {'precio': 0},
                      );
                      totalTienda += (getPrice(producto['precio']) * getCantidadProducto(rp));
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ExpansionTile(
                      title: Text(tiendaEntry.key.split(' (ID:')[0]),
                      subtitle: Text(
                        '${tiendaEntry.value.length} reservas - Total: ${formatoMoneda.format(totalTienda)}',
                      ),
                      children: tiendaEntry.value.map((reserva) {
                        double totalReserva = 0;
                        final reservaProductos = reserva['reserva_productos'] as List? ?? [];
                        final productos = reserva['productos'] as List? ?? [];

                        for (var rp in reservaProductos) {
                          final productoId = getProductoId(rp);
                          final producto = productos.firstWhere(
                            (p) => p['id'] == productoId,
                            orElse: () => {'precio': 0},
                          );
                          totalReserva += (getPrice(producto['precio']) * getCantidadProducto(rp));
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reserva #${reserva['id']?.toString() ?? "0"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  buildEstadoChip(getEstadoReserva(reserva['estado'])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...reservaProductos.map<Widget>((rp) {
                                final productoId = getProductoId(rp);
                                final producto = productos.firstWhere(
                                  (p) => p['id'] == productoId,
                                  orElse: () => {'precio': 0, 'nombre': 'Producto no encontrado'},
                                );
                                final precioTotal = getPrice(producto['precio']) * getCantidadProducto(rp);
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  getNombreProducto(producto),
                                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                                ),
                                                Text(
                                                  '${formatoMoneda.format(getPrice(producto['precio']))} c/u',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'Cant: ${getCantidadProducto(rp)}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              formatoMoneda.format(precioTotal),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (getEstadoReserva(reserva['estado']) == 'pendiente')
                                            IconButton(
                                              icon: const Icon(Icons.cancel),
                                              color: Colors.red,
                                              onPressed: () => _mostrarDialogoCancelacion(
                                                int.tryParse(reserva['id']?.toString() ?? '0') ?? 0
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (producto['promocion_nx'] != null || 
                                          producto['promocion_porcentaje'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: _buildPromotions(producto),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              if (getEstadoReserva(reserva['estado']) == 'pendiente')
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          getDiasRestantes(reserva['fecha_reserva']),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total: ${formatoMoneda.format(totalReserva)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      if (fechasOrdenadas.length > (paginaActual + 1) * itemsPorPagina)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                paginaActual++;
              });
            },
            child: const Text('Cargar más reservas'),
          ),
        ),
    ],
  );
}
  Future<void> _mostrarDialogoCancelacion(int reservaId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Reserva'),
          content: const Text('¿Estás seguro que deseas cancelar esta reserva?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cancelarReserva(reservaId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
  }
}