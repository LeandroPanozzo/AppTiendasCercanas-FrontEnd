//tengo que apretar en limpiar filtro para que me aparezcan las reservas
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth_service.dart';
import 'package:intl/intl.dart';

class ProductosReservadosPage extends StatefulWidget {
  final int tiendaId;
  final String tiendaNombre;

  const ProductosReservadosPage({
    Key? key,
    required this.tiendaId,
    required this.tiendaNombre,
  }) : super(key: key);

  @override
  _ProductosReservadosPageState createState() => _ProductosReservadosPageState();
}

class _ProductosReservadosPageState extends State<ProductosReservadosPage> {
  Map<String, Map<String, List<dynamic>>> reservasPorFechaYUsuario = {};
  Map<String, Map<String, List<dynamic>>> reservasFiltradas = {};
  bool isLoading = true;
  final formatoMoneda = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
  
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String _searchQuery = '';

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMoreItems = true;
  List<String> _allDates = [];

  void _loadMoreItems() {
    setState(() {
      _currentPage++;
    });
  }
List<String> _getPaginatedDates() {
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= _allDates.length) {
      _hasMoreItems = false;
      return [];
    }

    final endIndex = (startIndex + _itemsPerPage) <= _allDates.length 
        ? (startIndex + _itemsPerPage) 
        : _allDates.length;
    
    _hasMoreItems = endIndex < _allDates.length;
    return _allDates.sublist(startIndex, endIndex);
  }
  double getPrice(dynamic price) {
    if (price == null) return 0.0;
    try {
      if (price is num) return price.toDouble();
      return double.parse(price.toString());
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildPromotions(Map<String, dynamic> producto) {
    return Wrap(
      spacing: 8,
      children: [
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

  Widget buildEstadoChip(String estado) {
    estado = estado.toLowerCase();
    
    print('Construyendo chip para estado: $estado');
    
    Color color;
    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        break;
      case 'retirado':
        color = Colors.green;
        break;
      case 'cancelada':
        color = Colors.red;
        break;
      default:
        print('Estado no reconocido: $estado');
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    cargarReservas();  // Mantener cargarReservas() aquí
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
      final DateTime lastDate = DateTime(now.year + 1, now.month, now.day);
      
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
      reservasFiltradas = Map.from(reservasPorFechaYUsuario);
      _allDates = reservasFiltradas.keys.toList()..sort((a, b) => b.compareTo(a));
      _currentPage = 0; // Resetear la paginación cuando se limpian los filtros
    });
  }

  void _aplicarFiltros() {
    setState(() {
      if (_searchQuery.isEmpty && _selectedDate == null) {
        // Si no hay filtros activos, mostrar todas las reservas
        reservasFiltradas = Map.from(reservasPorFechaYUsuario);
      } else {
        reservasFiltradas = {};
        
        reservasPorFechaYUsuario.forEach((fecha, usuarios) {
          // Filtrar por fecha si hay una fecha seleccionada
          if (_selectedDate != null) {
            final fechaReserva = DateFormat('yyyy-MM-dd').parse(fecha);
            if (fechaReserva != _selectedDate) return;
          }

          // Filtrar por nombre de usuario si hay una búsqueda
          if (_searchQuery.isNotEmpty) {
            final usuariosFiltrados = Map.fromEntries(
              usuarios.entries.where((usuarioEntry) {
                return usuarioEntry.key.toLowerCase().contains(_searchQuery);
              }),
            );

            if (usuariosFiltrados.isNotEmpty) {
              reservasFiltradas[fecha] = usuariosFiltrados;
            }
          } else {
            reservasFiltradas[fecha] = usuarios;
          }
        });
      }

      // Actualizar la lista de todas las fechas después de filtrar
      _allDates = reservasFiltradas.keys.toList()..sort((a, b) => b.compareTo(a));
      _currentPage = 0; // Resetear la paginación cuando se aplican filtros
    });
  }

  Future<void> cargarReservas() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/reservas/'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> todasLasReservas = json.decode(response.body);
        
        final reservasTienda = todasLasReservas
            .where((reserva) => reserva['tienda']['id'] == widget.tiendaId)
            .toList();

        Map<String, Map<String, List<dynamic>>> agrupadas = {};
        
        for (var reserva in reservasTienda) {
          final fecha = reserva['fecha_reserva'];
          final usuario = reserva['usuario'];
          final userKey = '${usuario['user']['first_name']} ${usuario['user']['last_name']}';
          
          reserva['estado'] = (reserva['estado'] ?? 'pendiente').toLowerCase();
          
          agrupadas.putIfAbsent(fecha, () => {});
          agrupadas[fecha]!.putIfAbsent(userKey, () => []);
          agrupadas[fecha]![userKey]!.add(reserva);
        }

        setState(() {
          reservasPorFechaYUsuario = Map.fromEntries(
            agrupadas.entries.toList()..sort((a, b) => b.key.compareTo(a.key))
          );
          // Inicializar reservasFiltradas aquí con todas las reservas
          reservasFiltradas = Map.from(reservasPorFechaYUsuario);
          _allDates = reservasFiltradas.keys.toList()..sort((a, b) => b.compareTo(a));
          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar las reservas');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar las reservas: $e')),
        );
      }
    }
  }

Future<void> marcarComoRetirado(int reservaId) async {
  try {
    // Primero verificamos el estado actual
    bool reservaEncontrada = false;
    String estadoActual = '';
    
    // Buscamos la reserva y su estado actual
    reservasPorFechaYUsuario.forEach((fecha, usuarios) {
      usuarios.forEach((usuario, reservas) {
        for (var reserva in reservas) {
          if (reserva['id'] == reservaId) {
            estadoActual = reserva['estado']?.toLowerCase() ?? 'pendiente';
            reservaEncontrada = true;
          }
        }
      });
    });

    // Si la reserva ya está retirada, mostramos un mensaje y no hacemos la llamada
    if (estadoActual == 'retirado') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta reserva ya fue marcada como retirada'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/reservas/$reservaId/marcar-retirada/'),
      headers: {
        'Authorization': 'Bearer ${AuthService.accessToken}',
        'Content-Type': 'application/json',
      },
      body: json.encode({}),
    );

    if (response.statusCode == 200) {
      final updatedReserva = json.decode(response.body);
      
      setState(() {
        reservasPorFechaYUsuario.forEach((fecha, usuarios) {
          usuarios.forEach((usuario, reservas) {
            for (var i = 0; i < reservas.length; i++) {
              if (reservas[i]['id'] == reservaId) {
                reservas[i] = updatedReserva;
                // Aseguramos que el estado se actualice correctamente
                reservas[i]['estado'] = 'retirado';
              }
            }
          });
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva marcada como retirada'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Si el error es porque ya está retirada, actualizamos el estado local
      if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        if (errorResponse['error']?.contains('Solo se pueden marcar como retiradas las reservas pendientes') ?? false) {
          // Actualizamos el estado local para reflejar que está retirada
          setState(() {
            reservasPorFechaYUsuario.forEach((fecha, usuarios) {
              usuarios.forEach((usuario, reservas) {
                for (var i = 0; i < reservas.length; i++) {
                  if (reservas[i]['id'] == reservaId) {
                    reservas[i]['estado'] = 'retirado';
                  }
                }
              });
            });
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Esta reserva ya estaba marcada como retirada'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
      
      // Para otros tipos de errores
      final errorMessage = response.body.isNotEmpty 
          ? json.decode(response.body)['error'] ?? 'Error desconocido'
          : 'Error desconocido';
          
      throw Exception(errorMessage);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    // Recargamos los datos en caso de error
    await cargarReservas();
  }
}
Future<void> cancelarReserva(int reservaId) async {
  // Primero eliminamos la reserva localmente
  setState(() {
    reservasPorFechaYUsuario.forEach((fecha, usuarios) {
      usuarios.forEach((usuario, reservas) {
        reservas.removeWhere((reserva) => reserva['id'] == reservaId);
        // Si el usuario ya no tiene reservas, lo eliminamos
        if (reservas.isEmpty) {
          usuarios.remove(usuario);
        }
      });
      // Si la fecha ya no tiene usuarios, la eliminamos
      if (usuarios.isEmpty) {
        reservasPorFechaYUsuario.remove(fecha);
      }
    });
  });

  try {
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/reservas/$reservaId/cancelar/'),
      headers: {
        'Authorization': 'Bearer ${AuthService.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva cancelada exitosamente')),
      );
    } else {
      // Si hay error, recargamos para restaurar el estado
      cargarReservas();
      throw Exception('Error al cancelar la reserva');
    }
  } catch (e) {
    // Si hay error, recargamos para restaurar el estado
    cargarReservas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

@override
Widget build(BuildContext context) {
  final paginatedDates = _getPaginatedDates();

  return Scaffold(
    appBar: AppBar(
      title: Text('Reservas - ${widget.tiendaNombre}'),
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
                  hintText: 'Buscar por nombre de usuario...',
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
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservasFiltradas.isEmpty
              ? const Center(child: Text('No hay reservas que coincidan con los filtros'))
              : ListView(
                  children: [
                    ...paginatedDates.map((fecha) {
                      final usuariosPorFecha = reservasFiltradas[fecha]!;

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ExpansionTile(
                          title: Text('Fecha: $fecha'),
                          subtitle: Text('${usuariosPorFecha.length} usuarios'),
                          children: usuariosPorFecha.entries.map((usuarioEntry) {
                            double totalUsuario = 0;
                            for (var reserva in usuarioEntry.value) {
                              for (var rp in reserva['reserva_productos']) {
                                final producto = reserva['productos']
                                    .firstWhere((p) => p['id'] == rp['producto']);
                                totalUsuario += getPrice(producto['precio']) * rp['cantidad'];
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ExpansionTile(
                                title: Text(usuarioEntry.key),
                                subtitle: Text(
                                  '${usuarioEntry.value.length} reservas - Total: ${formatoMoneda.format(totalUsuario)}',
                                ),
                                children: usuarioEntry.value.map((reserva) {
                                  double totalReserva = 0;
                                  return Container(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Reserva #${reserva['id']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            buildEstadoChip(reserva['estado'] ?? 'pendiente'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...reserva['reserva_productos'].map<Widget>((rp) {
                                          final producto = reserva['productos']
                                              .firstWhere((p) => p['id'] == rp['producto']);
                                          final precioUnitario = getPrice(producto['precio']);
                                          final cantidad = rp['cantidad'];
                                          final precioTotal = precioUnitario * cantidad;
                                          totalReserva += precioTotal;

                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
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
                                                            producto['nombre'],
                                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          Text(
                                                            '${formatoMoneda.format(precioUnitario)} c/u',
                                                            style: TextStyle(
                                                              color: Colors.grey.shade600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          if (producto['precio_original'] != null &&
                                                              precioUnitario < getPrice(producto['precio_original']))
                                                            Text(
                                                              '${formatoMoneda.format(getPrice(producto['precio_original']))}',
                                                              style: TextStyle(
                                                                color: Colors.grey.shade600,
                                                                fontSize: 12,
                                                                decoration: TextDecoration.lineThrough,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        'Cant: $cantidad',
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
                                                    if (reserva['estado']?.toLowerCase() != 'retirado')
                                                      Expanded(
                                                        flex: 2,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.check_circle),
                                                              color: Colors.green,
                                                              onPressed: () => marcarComoRetirado(reserva['id']),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.cancel),
                                                              color: Colors.red,
                                                              onPressed: () => cancelarReserva(reserva['id']),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                if (producto['promocion_nx'] != null || 
                                                    producto['promocion_porcentaje'] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                                    child: _buildPromotions(producto),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
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
                    }).toList(),
                    if (_hasMoreItems)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: _loadMoreItems,
                            child: const Text('Cargar más reservas'),
                          ),
                        ),
                      ),
                  ],
                ),
    ),
  );
}
}