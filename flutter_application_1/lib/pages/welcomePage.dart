import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './custom_scaffold.dart';
import '../profile_service.dart';
import '../api_service.dart';
import './productDetailPage.dart';
import './custom_search_bar.dart';
import '../auth_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with WidgetsBindingObserver {
  Map<String, dynamic>? currentFilters;
  bool isLoggedIn = false;
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> filteredProductos = [];
  List<Map<String, dynamic>> displayedProductos = []; // New list for displayed products
  bool isLoading = true;
  bool isLoadingMore = false; // New loading flag for pagination
  String errorMessage = '';
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController(); // New scroll controller
  static const int _pageSize = 20; // Number of items per page

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _setupScrollController();
  }
  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreProducts();
      }
    });
  }
  void _loadMoreProducts() {
    if (!isLoadingMore && displayedProductos.length < filteredProductos.length) {
      setState(() {
        isLoadingMore = true;
      });

      // Simulate a small delay for better UX
      Future.delayed(const Duration(milliseconds: 500), () {
        final nextProducts = filteredProductos.skip(displayedProductos.length).take(_pageSize).toList();
        setState(() {
          displayedProductos.addAll(nextProducts);
          isLoadingMore = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkLoginStatus();
    if (isLoggedIn) {
      await _loadProductos();
    }
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

  // Añadir estado para los filtros

 void _handleFilters(Map<String, dynamic> filters) {
  setState(() {
    currentFilters = filters;
    
    // Primero filtramos los productos
    filteredProductos = productos.where((producto) {
      // Aplicar filtro de búsqueda si existe
      if (searchQuery.isNotEmpty) {
        final nombreProducto = normalizeText(producto['nombre'] ?? '').toLowerCase();
        final descripcion = normalizeText(producto['descripcion'] ?? '').toLowerCase();
        final nombreTienda = normalizeText(producto['tienda']?['nombre'] ?? '').toLowerCase();
        
        if (!nombreProducto.contains(searchQuery) &&
            !descripcion.contains(searchQuery) &&
            !nombreTienda.contains(searchQuery)) {
          return false;
        }
      }

      // Obtener los valores de los filtros
      final RangeValues priceRange = filters['priceRange'] as RangeValues;
      final bool isService = filters['isService'] as bool;
      final bool isReservable = filters['isReservable'] as bool;
      final bool hasDiscount = filters['hasDiscount'] as bool;
      final bool hasPromotion = filters['hasPromotion'] as bool;
      final List<String> selectedPaymentMethods = List<String>.from(filters['paymentMethods'] ?? []);
      final String? selectedCategory = filters['category'] as String?;

      // Aplicar filtro de precio
      final precio = double.tryParse(producto['precio'].toString()) ?? 0;
      if (precio < priceRange.start || precio > priceRange.end) {
        return false;
      }

      // Aplicar filtro de servicio
      if (isService && !(producto['es_servicio'] ?? false)) {
        return false;
      }

      // Aplicar filtro de reservas
      if (isReservable && !(producto['permite_reservas'] ?? false)) {
        return false;
      }

      // Aplicar filtro de descuento
      if (hasDiscount) {
        final precioOriginal = double.tryParse(producto['precio_original']?.toString() ?? '0') ?? 0;
        final precioActual = double.tryParse(producto['precio']?.toString() ?? '0') ?? 0;
        if (precioOriginal <= precioActual) {
          return false;
        }
      }

      // Aplicar filtro de promociones
      if (hasPromotion) {
        final hasNxMPromo = producto['promocion_nx'] != null && 
                           producto['promocion_nx'].toString().isNotEmpty;
        final hasPercentagePromo = producto['promocion_porcentaje'] != null && 
                                 producto['promocion_unidad'] != null &&
                                 double.tryParse(producto['promocion_porcentaje'].toString())! > 0;
        if (!hasNxMPromo && !hasPercentagePromo) {
          return false;
        }
      }

      // Aplicar filtro de categoría
      if (selectedCategory != null && selectedCategory.isNotEmpty) {
        final tiendaCategoria = producto['tienda']?['categoria']?.toString() ?? '';
        if (tiendaCategoria != selectedCategory) {
          return false;
        }
      }

      // Aplicar filtro de métodos de pago
      if (selectedPaymentMethods.isNotEmpty) {
        final tienda = producto['tienda'] ?? {};
        bool hasMatchingPaymentMethod = selectedPaymentMethods.any((method) {
          return tienda[method] == true;
        });
        if (!hasMatchingPaymentMethod) {
          return false;
        }
      }

      return true;
    }).toList();

    // Después de filtrar, actualizamos los productos mostrados
    displayedProductos = filteredProductos.take(_pageSize).toList();
  });
}

   void _handleSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      if (searchQuery.isEmpty) {
        filteredProductos = List.from(productos);
      } else {
        filteredProductos = productos.where((producto) {
          final nombreProducto = normalizeText(producto['nombre'] ?? '').toLowerCase();
          final descripcion = normalizeText(producto['descripcion'] ?? '').toLowerCase();
          final nombreTienda = normalizeText(producto['tienda']?['nombre'] ?? '').toLowerCase();
          
          return nombreProducto.contains(searchQuery) ||
                 descripcion.contains(searchQuery) ||
                 nombreTienda.contains(searchQuery);
        }).toList();
      }
      // Reset displayed products to first page after search
      displayedProductos = filteredProductos.take(_pageSize).toList();
  });
  }


  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getString('token') != null;
    });
    if (isLoggedIn) {
      _loadProductos();
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final city = await ProfileService().getCity();
      final productosData = await ApiService.obtenerProductosPorCiudad(city);
      
      productosData.sort((a, b) {
        final fechaA = DateTime.parse(a['fecha_creacion'] ?? '');
        final fechaB = DateTime.parse(b['fecha_creacion'] ?? '');
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        productos = productosData;
        filteredProductos = productosData;
        displayedProductos = productosData.take(_pageSize).toList(); // Initialize with first page
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar productos. Por favor, inténtelo de nuevo.';
      });
    }
  }
  Future<void> _logout() async {
  await AuthService.logout(); // Usar el AuthService centralizado
  setState(() {
    isLoggedIn = false;
    productos = [];
    filteredProductos = [];
    displayedProductos = [];
  });
  // No navegar aquí, dejar que CustomScaffold maneje la navegación
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
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
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
          : const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey,
              ),
            ),
    );
  }

@override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Bienvenido',
      isLoggedIn: isLoggedIn,
      onLogout: _logout,
      searchBar: isLoggedIn ? CustomSearchBar(
        onSearch: _handleSearch,
        hintText: 'Buscar productos o tiendas...',
        showFilterButton: false,
        // Pass products and store information from your data
        products: productos,
        stores: _extractUniqueStores(productos),
      ) : null,
      onApplyFilters: isLoggedIn ? _handleFilters : null,
      currentFilters: currentFilters,
      body: isLoggedIn
        ? isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayedProductos.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isNotEmpty
                          ? 'No se encontraron productos que coincidan con su búsqueda.'
                          : errorMessage.isEmpty
                              ? 'No hay productos disponibles en tu ciudad.'
                              : errorMessage,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: displayedProductos.length + 1, // +1 for loading indicator
                    itemBuilder: (context, index) {
                      if (index == displayedProductos.length) {
                        // Show loading indicator at the bottom if more items are available
                        if (isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }

                      final producto = displayedProductos[index];
                      final tienda = producto['tienda'] ?? {};

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
                                    Row(
                                      children: [
                                        const Icon(Icons.store, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Tienda: ${normalizeText(tienda['nombre'] ?? 'Sin nombre')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${normalizeText(tienda['direccion_calle'] ?? '')} ${tienda['direccion_numero'] ?? ''}, ${normalizeText(tienda['ciudad'] ?? '')}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
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
                                            // Check and display original price if there's a discount
                                            if (producto['precio_original'] != null && 
                                                producto['precio'] != null) ...[
                                              Builder(builder: (context) {
                                                final precioActual = double.tryParse(producto['precio'].toString()) ?? 0;
                                                final precioOriginal = double.tryParse(producto['precio_original'].toString()) ?? 0;
                                                
                                                if (precioActual < precioOriginal) {
                                                  return Text(
                                                    _formatPrice(producto['precio_original']),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              }),
                                            ],
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
                                        Wrap(
                                          direction: Axis.vertical, // Cambiar a vertical para apilar las etiquetas
                                          spacing: 4, // Reducir el espaciado vertical
                                          children: [
                                            // Promoción NxM
                                            if (producto['promocion_nx'] != null && 
                                                producto['promocion_nx'].toString().isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, 
                                                  vertical: 4
                                                ),
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, 
                                                  vertical: 4
                                                ),
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8, 
                                                vertical: 4
                                              ),
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
                )
      : const Center(
          child: Text(
            'Por favor, inicie sesión para ver los productos',
            style: TextStyle(fontSize: 24),
          ),
        ),
  );
}
}
// Add this helper method to extract unique stores from products
List<Map<String, dynamic>> _extractUniqueStores(List<Map<String, dynamic>> products) {
  final Map<String, Map<String, dynamic>> uniqueStores = {};
  
  for (var product in products) {
    final store = product['tienda'];
    if (store != null && store['id'] != null) {
      final storeId = store['id'].toString();
      if (!uniqueStores.containsKey(storeId)) {
        uniqueStores[storeId] = Map<String, dynamic>.from(store);
      }
    }
  }
  
  return uniqueStores.values.toList();
}