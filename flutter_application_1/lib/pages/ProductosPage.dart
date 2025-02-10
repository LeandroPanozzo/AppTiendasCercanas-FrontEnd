//vista donde se muestran todos los articulos de la tienda seleccionada
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import './EditProductoPage.dart';
import './filter_panel.dart';
import './custom_search_bar.dart';

class ProductosPage extends StatefulWidget {
  final int tiendaId;

  const ProductosPage({required this.tiendaId, Key? key}) : super(key: key);

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List<dynamic> productos = [];
  List<dynamic> filteredProductos = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = '';
  Map<String, dynamic>? currentFilters;
  
  // Pagination variables
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    cargarProductos();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && _hasMore) {
        cargarMasProductos();
      }
    }
  }

  Future<void> cargarProductos() async {
    setState(() {
      isLoading = true;
      _page = 1;
      productos = [];
      filteredProductos = [];
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/productos/?tienda=${widget.tiendaId}&ordering=-fecha_creacion&offset=0&limit=$_limit'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);
        setState(() {
          productos = decodedResponse;
          filteredProductos = productos;
          _hasMore = decodedResponse.length >= _limit;
          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los productos');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> cargarMasProductos() async {
    if (isLoadingMore || !_hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final offset = productos.length;
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/productos/?tienda=${widget.tiendaId}&ordering=-fecha_creacion&offset=$offset&limit=$_limit'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> newProducts = json.decode(response.body);
        
        setState(() {
          productos.addAll(newProducts);
          applyFilters(); // Reapply filters to include new products
          _hasMore = newProducts.length >= _limit;
          isLoadingMore = false;
        });
      } else {
        throw Exception('Error al cargar más productos');
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más productos: $e')),
      );
    }
  }
void handleSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      applyFilters();
    });
  }

  void applyFilters() {
    List<dynamic> tempProducts = List.from(productos);

    // Aplicar búsqueda
    if (searchQuery.isNotEmpty) {
      tempProducts = tempProducts.where((producto) =>
        producto['nombre'].toString().toLowerCase().contains(searchQuery)
      ).toList();
    }


    // Aplicar filtros si existen
    if (currentFilters != null) {
      final priceRange = currentFilters!['priceRange'] as RangeValues;
      tempProducts = tempProducts.where((producto) {
        final price = double.parse(producto['precio'].toString());
        final isInPriceRange = price >= priceRange.start && price <= priceRange.end;
        
        // Filtro de servicio
        final bool matchesServiceFilter = !currentFilters!['isService'] || 
          producto['es_servicio'] == currentFilters!['isService'];
        
        // Filtro de reservas
        final bool matchesReservableFilter = !currentFilters!['isReservable'] || 
          producto['permite_reservas'] == currentFilters!['isReservable'];
        
        // Filtro de descuento
        final bool matchesDiscountFilter = !currentFilters!['hasDiscount'] || 
          (producto['precio_original'] != null && 
           producto['precio'] != null &&
           double.parse(producto['precio'].toString()) < 
           double.parse(producto['precio_original'].toString()));

        // Filtro de promociones
        final bool matchesPromotionFilter = !currentFilters!['hasPromotion'] || 
          (
            // Promoción NxM
            (producto['promocion_nx'] != null && 
             producto['promocion_nx'].toString().isNotEmpty) ||
            // Promoción porcentual
            (producto['promocion_porcentaje'] != null && 
             producto['promocion_unidad'] != null &&
             double.parse(producto['promocion_porcentaje'].toString()) > 0)
          );

        // Filtro de categoría
        final String? selectedCategory = currentFilters!['category'] as String?;
        final bool matchesCategoryFilter = selectedCategory == null || 
                                         selectedCategory.isEmpty ||
                                         producto['tienda']?['categoria']?.toString() == selectedCategory;

        // Filtro de métodos de pago
        final List<String> selectedPaymentMethods = List<String>.from(currentFilters!['paymentMethods'] ?? []);
        final bool matchesPaymentMethodFilter = selectedPaymentMethods.isEmpty ||
          selectedPaymentMethods.any((method) => 
            (producto['tienda']?['metodos_pago'] as List<dynamic>?)
              ?.map((m) => m['nombre'].toString())
              .contains(method) ?? false);

        return isInPriceRange && 
               matchesServiceFilter && 
               matchesReservableFilter && 
               matchesDiscountFilter && 
               matchesPromotionFilter &&
               matchesCategoryFilter &&
               matchesPaymentMethodFilter;
      }).toList();
    }

    setState(() {
      filteredProductos = tempProducts;
    });
  }

  void handleFilters(Map<String, dynamic> filters) {
    setState(() {
      currentFilters = filters;
      applyFilters();
    });
  }

  Widget _buildProductImage(String? imageUrl) {
    return Container(
      height: 50,  // Maintaining the original size from ProductosPage
      width: 50,   // Maintaining the original size from ProductosPage
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200], // Light grey background
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 24,  // Smaller size to match the 50x50 container
                      color: Colors.grey[600],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 24,  // Smaller size to match the 50x50 container
                color: Colors.grey[600],
              ),
            ),
    );
  }

  
 Future<void> _confirmarEliminacion(int productoId) async {
   final confirmar = await showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: const Text('Confirmar eliminación'),
       content: const Text('¿Estás seguro de eliminar este producto?'),
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
   );

   if (confirmar == true) {
     try {
       final response = await http.delete(
         Uri.parse('http://127.0.0.1:8000/productos/$productoId/'),
         headers: {'Authorization': 'Bearer ${AuthService.accessToken}'},
       );

       if (response.statusCode == 204) {
         cargarProductos();
       } else {
         throw Exception('Error al eliminar el producto');
       }
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: $e')),
       );
     }
   }
 }

Widget _buildPromotions(Map<String, dynamic> producto) {
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
              fontSize: 12,
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
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}

Widget _buildPriceInfo(Map<String, dynamic> producto) {
   final double? precioOriginal = producto['precio_original']?.toString().isEmpty ?? true
       ? null
       : double.tryParse(producto['precio_original'].toString());
   
   final double? porcentajeDescuento = producto['porcentaje_descuento']?.toString().isEmpty ?? true
       ? null
       : double.tryParse(producto['porcentaje_descuento'].toString());

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       if (precioOriginal != null && porcentajeDescuento != null && porcentajeDescuento > 0) ...[
         Text(
           'Precio actual: \$${producto['precio']}',
           style: const TextStyle(fontWeight: FontWeight.bold),
         ),
         Text(
           'Precio original: \$${precioOriginal.toStringAsFixed(2)}\nDescuento: ${porcentajeDescuento.toStringAsFixed(2)}%',
           style: const TextStyle(
             color: Colors.green,
             fontWeight: FontWeight.bold,
           ),
         ),
       ] else 
         Text(
           'Precio: \$${producto['precio']}',
           style: const TextStyle(fontWeight: FontWeight.bold),
         ),
     ],
   );
}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: CustomSearchBar(
            onSearch: handleSearch,
            showFilterButton: false,
            onFilterTap: () {
              Scaffold.of(context).openEndDrawer();
            },
            hintText: 'Buscar productos...',
          ),
        ),
      ),
      endDrawer: FilterPanel(
        onApplyFilters: handleFilters,
        onClose: () => Navigator.pop(context),
        currentFilters: currentFilters,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredProductos.isEmpty
              ? const Center(child: Text('No hay productos que coincidan con la búsqueda'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredProductos.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredProductos.length) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: isLoadingMore
                              ? const CircularProgressIndicator()
                              : const SizedBox(),
                        ),
                      );
                    }

                    final producto = filteredProductos[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: _buildProductImage(producto['url_imagen']),
                        title: Text(producto['nombre']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPriceInfo(producto),
                            const SizedBox(height: 4),
                            _buildPromotions(producto),
                            const SizedBox(height: 4),
                            if (!producto['es_servicio'] && producto['permite_reservas'] == true)
                              Text(
                                'Cantidad disponible: ${producto['cantidad_disponible'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              producto['disponibilidad'] == true 
                                  ? 'Producto disponible' 
                                  : 'Producto no disponible',
                              style: TextStyle(
                                color: producto['disponibilidad'] == true 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                            ),
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
                                    builder: (context) => EditProductoPage(producto: producto),
                                  ),
                                );
                                if (result == true) {
                                  cargarProductos();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _confirmarEliminacion(producto['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}