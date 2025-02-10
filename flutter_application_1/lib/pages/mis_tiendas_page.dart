import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import './EditTiendaPage.dart';
import './AddProductoPage.dart';
import './ProductosPage.dart';
import './ProductosReservadosPage.dart';

class MisTiendasPage extends StatefulWidget {
  const MisTiendasPage({super.key});

  @override
  State<MisTiendasPage> createState() => _MisTiendasPageState();
}

class _MisTiendasPageState extends State<MisTiendasPage> {
  List<dynamic> tiendas = [];
  List<dynamic> tiendasFiltradas = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarTiendas();
    _searchController.addListener(_filtrarTiendas);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      if (!isLoadingMore && hasMoreData && _searchController.text.isEmpty) {
        cargarMasTiendas();
      }
    }
  }

  void _filtrarTiendas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      tiendasFiltradas = tiendas.where((tienda) {
        final nombreMatch = tienda['nombre'].toString().toLowerCase().contains(query);
        final direccionMatch = tienda['direccion_calle'].toString().toLowerCase().contains(query);
        return nombreMatch || direccionMatch;
      }).toList();
    });
  }

  String normalizeText(String text) {
    try {
      String decoded = utf8.decode(utf8.encode(text));
      
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

  Future<void> cargarTiendas() async {
    try {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/mis-tiendas/?page=$currentPage&per_page=$itemsPerPage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedTiendas = json.decode(response.body);
        
        final List<Map<String, dynamic>> normalizedTiendas = decodedTiendas.map((tienda) => {
          'id': tienda['id'],
          'nombre': normalizeText(tienda['nombre']?.toString() ?? ''),
          'categoria': normalizeText(tienda['categoria']?.toString() ?? ''),
          'direccion_calle': normalizeText(tienda['direccion_calle']?.toString() ?? ''),
          'direccion_numero': tienda['direccion_numero']?.toString() ?? '',
          'ciudad': normalizeText(tienda['ciudad']?.toString() ?? ''),
        }).toList();

        setState(() {
          tiendas = normalizedTiendas;
          tiendasFiltradas = normalizedTiendas;
          isLoading = false;
          hasMoreData = normalizedTiendas.length == itemsPerPage;
        });
      } else {
        throw Exception('Error al cargar las tiendas');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las tiendas: $e')),
      );
    }
  }

  Future<void> cargarMasTiendas() async {
    if (isLoadingMore || !hasMoreData) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final nextPage = currentPage + 1;
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/mis-tiendas/?page=$nextPage&per_page=$itemsPerPage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedTiendas = json.decode(response.body);
        
        final List<Map<String, dynamic>> normalizedTiendas = decodedTiendas.map((tienda) => {
          'id': tienda['id'],
          'nombre': normalizeText(tienda['nombre']?.toString() ?? ''),
          'categoria': normalizeText(tienda['categoria']?.toString() ?? ''),
          'direccion_calle': normalizeText(tienda['direccion_calle']?.toString() ?? ''),
          'direccion_numero': tienda['direccion_numero']?.toString() ?? '',
          'ciudad': normalizeText(tienda['ciudad']?.toString() ?? ''),
        }).toList();

        setState(() {
          tiendas.addAll(normalizedTiendas);
          tiendasFiltradas = tiendas;
          currentPage = nextPage;
          hasMoreData = normalizedTiendas.length == itemsPerPage;
          isLoadingMore = false;
        });
      } else {
        throw Exception('Error al cargar más tiendas');
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más tiendas: $e')),
      );
    }
  }

  Future<void> eliminarTienda(int tiendaId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/tiendas/$tiendaId/'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          tiendas.removeWhere((tienda) => tienda['id'] == tiendaId);
          tiendasFiltradas.removeWhere((tienda) => tienda['id'] == tiendaId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tienda eliminada exitosamente')),
        );
      } else {
        throw Exception('Error al eliminar la tienda');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/welcome');
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
          title: const Text('Mis Tiendas'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o dirección',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarTiendas();
                        },
                      )
                    : null,
                ),
              ),
            ),
            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : tiendasFiltradas.isEmpty
                  ? const Center(child: Text('No se encontraron tiendas'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: tiendasFiltradas.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == tiendasFiltradas.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final tienda = tiendasFiltradas[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(tienda['nombre']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Categoría: ${tienda['categoria']}'),
                                    Text('Dirección: ${tienda['direccion_calle']} ${tienda['direccion_numero']}'),
                                    Text('Ciudad: ${tienda['ciudad']}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditTiendaPage(tienda: tienda),
                                          ),
                                        );
                                        if (result == true) {
                                          cargarTiendas();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddProductoPage(tiendaId: tienda['id']),
                                          ),
                                        );
                                        if (result == true) {
                                          cargarTiendas();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (BuildContext context) => AlertDialog(
                                          title: const Text('Confirmar eliminación'),
                                          content: const Text('¿Estás seguro de que deseas eliminar esta tienda?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                eliminarTienda(tienda['id']);
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductosPage(tiendaId: tienda['id']),
                                            ),
                                          );
                                        },
                                        child: const Text('Mis Productos'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductosReservadosPage(
                                                tiendaId: tienda['id'],
                                                tiendaNombre: tienda['nombre'],
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Productos Reservados'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}