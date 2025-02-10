//cuando apretamos en ver mas productos de la tienda aparecera esta pagina

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import './ProductDetailPage.dart';
import './filter_panel.dart';
import './custom_search_bar.dart';

class TiendaProductosPage extends StatefulWidget {
  final Map<String, dynamic> tienda;

  const TiendaProductosPage({
    super.key,
    required this.tienda,
  });

  @override
  State<TiendaProductosPage> createState() => _TiendaProductosPageState();
}

class _TiendaProductosPageState extends State<TiendaProductosPage> {
  List<dynamic> productos = [];
  List<dynamic> filteredProductos = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String searchQuery = '';
  Map<String, dynamic>? currentFilters;
  ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  bool hasMoreProducts = true;
  static const int pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    cargarProductos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && hasMoreProducts) {
        cargarMasProductos();
      }
    }
  }

  Future<void> cargarProductos() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/productos/?tienda=${widget.tienda['id']}&ordering=-fecha_creacion&page=$currentPage&page_size=$pageSize'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> newProducts = [];
        bool hasNext = false;

        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Respuesta paginada
          newProducts = data['results'] as List<dynamic>;
          hasNext = data['next'] != null;
        } else if (data is List<dynamic>) {
          // Respuesta no paginada
          newProducts = data;
          hasNext = false;
        }

        setState(() {
          productos = newProducts;
          filteredProductos = productos;
          isLoading = false;
          hasMoreProducts = hasNext;
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
    if (isLoadingMore || !hasMoreProducts) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final nextPage = currentPage + 1;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/productos/?tienda=${widget.tienda['id']}&ordering=-fecha_creacion&page=$nextPage&page_size=$pageSize'),
        headers: {
          'Authorization': 'Bearer ${AuthService.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> newProducts = [];
        bool hasNext = false;

        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // Respuesta paginada
          newProducts = data['results'] as List<dynamic>;
          hasNext = data['next'] != null;
        } else if (data is List<dynamic>) {
          // Respuesta no paginada
          newProducts = data;
          hasNext = false;
        }

        setState(() {
          currentPage = nextPage;
          productos.addAll(newProducts);
          applyFilters(); // Re-apply filters to include new products
          hasMoreProducts = hasNext;
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
        producto['nombre'].toString().toLowerCase().contains(searchQuery) ||
        (producto['descripcion'] != null && 
         producto['descripcion'].toString().toLowerCase().contains(searchQuery))
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
          (producto['porcentaje_descuento'] != null && 
           producto['porcentaje_descuento'].toString().isNotEmpty && 
           double.parse(producto['porcentaje_descuento'].toString()) > 0);

        // Filtro de promociones
        final bool matchesPromotionFilter = !currentFilters!['hasPromotion'] || 
          (
            (producto['promocion_nx'] != null && 
             producto['promocion_nx'].toString().isNotEmpty) ||
            (producto['promocion_porcentaje'] != null && 
             producto['promocion_porcentaje'].toString().isNotEmpty && 
             double.parse(producto['promocion_porcentaje'].toString()) > 0 && 
             producto['promocion_unidad'] != null)
          );

        // Filtro de categoría
        final String? selectedCategory = currentFilters!['category'] as String?;
        final bool matchesCategoryFilter = selectedCategory == null || 
                                         selectedCategory.isEmpty ||
                                         widget.tienda['categoria']?.toString() == selectedCategory;

        // Filtro de métodos de pago
        final List<String> selectedPaymentMethods = List<String>.from(currentFilters!['paymentMethods'] ?? []);
        final bool matchesPaymentMethodFilter = selectedPaymentMethods.isEmpty ||
          selectedPaymentMethods.any((method) => 
            widget.tienda[method] == true  // Check boolean field directly
          );

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


  String _formatPrice(dynamic price) {
    if (price == null) return 'Precio no disponible';
    try {
      final double numPrice = double.parse(price.toString());
      return '\$${numPrice.toStringAsFixed(2)}';
    } catch (e) {
      return 'Precio inválido';
    }
  }

  Widget _buildProductImage(String? imageUrl) {
  return Container(
    height: 100,
    width: 100,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey[200], // Fondo gris claro
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
                    Icons.image_not_supported_outlined, // Icono más detallado que el original
                    size: 40,
                    color: Colors.grey[600], // Un gris más oscuro para mejor contraste
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
              size: 40,
              color: Colors.grey[600], // Un gris más oscuro para mejor contraste
            ),
          ),
  );
}
  Widget _buildPromotions(Map<String, dynamic> producto) {
  return Wrap(
    direction: Axis.vertical, // Cambiar a vertical
    spacing: 4, // Reducir el espaciado vertical
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
      
      // Estado de disponibilidad
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (producto['disponibilidad'] ?? false)
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          (producto['disponibilidad'] ?? false)
              ? 'Disponible'
              : 'No disponible',
          style: TextStyle(
            color: (producto['disponibilidad'] ?? false)
                ? Colors.green
                : Colors.red,
          ),
        ),
      ),
    ],
  );
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

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de ${widget.tienda['nombre']}'),
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
              ? const Center(child: Text('No hay productos que coincidan con los criterios'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredProductos.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredProductos.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final producto = filteredProductos[index];
                    final tienda = widget.tienda;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              producto: producto,
                              tienda: tienda,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              _buildProductImage(producto['url_imagen']),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      normalizeText(producto['nombre'] ?? 'Sin nombre'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!producto['es_servicio']) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            producto['permite_reservas'] == true
                                                ? 'Cantidad disponible: ${producto['cantidad_disponible'] ?? 0}'
                                                : 'No permite reservas',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory, size: 16),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Servicio',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (producto['descripcion'] != null &&
                                        producto['descripcion'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        normalizeText(producto['descripcion']),
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (producto['precio_original'] != null &&
                                                (double.tryParse(producto['precio'].toString()) ?? 0) <
                                                    (double.tryParse(producto['precio_original'].toString()) ?? 0))
                                              Text(
                                                _formatPrice(producto['precio_original']),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            Text(
                                              _formatPrice(producto['precio']),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: _buildPromotions(producto),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}