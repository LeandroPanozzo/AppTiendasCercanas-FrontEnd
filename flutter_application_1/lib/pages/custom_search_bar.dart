import 'package:flutter/material.dart';
import 'dart:async';
import './tiendaProductosPage.dart';

class CustomSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSearch;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;
  final String hintText;
  final List<Map<String, dynamic>>? stores;
  final List<Map<String, dynamic>>? products;
  
  const CustomSearchBar({
    Key? key,
    required this.onSearch,
    this.showFilterButton = true,
    this.onFilterTap,
    this.hintText = '¿Qué estás buscando?',
    this.stores,
    this.products,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showResults = false;
  String _currentQuery = '';
  List<Map<String, dynamic>> _filteredStores = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showResults = _focusNode.hasFocus && _currentQuery.isNotEmpty;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentQuery = query.toLowerCase();
        _showResults = _focusNode.hasFocus && _currentQuery.isNotEmpty;
        _filterResults();
      });
      widget.onSearch(query);
    });
  }
  
  void _filterResults() {
    if (_currentQuery.isEmpty || widget.stores == null) {
      _filteredStores = [];
      _filteredProducts = [];
      return;
    }
    
    // Filter stores
    _filteredStores = widget.stores!.where((store) {
      final storeName = normalizeText(store['nombre'] ?? '').toLowerCase();
      return storeName.contains(_currentQuery);
    }).take(3).toList(); // Limit to top 3 results
    
    // Filter products by store name
    if (widget.products != null) {
      _filteredProducts = widget.products!.where((product) {
        final productName = normalizeText(product['nombre'] ?? '').toLowerCase();
        final storeName = normalizeText(product['tienda']?['nombre'] ?? '').toLowerCase();
        return productName.contains(_currentQuery) || storeName.contains(_currentQuery);
      }).take(5).toList(); // Limit to top 5 results
    } else {
      _filteredProducts = [];
    }
  }
  
  String normalizeText(String text) {
    try {
      String decoded = text
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
      return decoded;
    } catch (e) {
      return text;
    }
  }
  
  void _navigateToStoreProducts(BuildContext context, Map<String, dynamic> store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TiendaProductosPage(
          tienda: store,
        ),
      ),
    );
    
    // Clear search and hide results after navigation
    setState(() {
      _showResults = false;
      _searchController.clear();
      _currentQuery = '';
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: kToolbarHeight + 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                _focusNode.unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      widget.onSearch(value);
                      _focusNode.unfocus();
                      setState(() => _showResults = false);
                    },
                  ),
                ),
              ),
              if (widget.showFilterButton) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: widget.onFilterTap,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_showResults && (_filteredStores.isNotEmpty || _filteredProducts.isNotEmpty))
          Positioned(
            top: kToolbarHeight + 8,
            left: 16,
            right: widget.showFilterButton ? 64 : 16,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    if (_filteredStores.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Tiendas',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._filteredStores.map((store) => ListTile(
                        leading: const Icon(Icons.store, color: Colors.blue),
                        title: Text(normalizeText(store['nombre'] ?? 'Sin nombre')),
                        subtitle: Text(
                          normalizeText(store['direccion_calle'] ?? '') + 
                          ' ' + 
                          (store['direccion_numero']?.toString() ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _navigateToStoreProducts(context, store),
                      )),
                      const Divider(),
                    ],
                    if (_filteredProducts.isNotEmpty && _filteredStores.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Productos',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    ..._filteredProducts.map((product) {
                      final tienda = product['tienda'] ?? {};
                      return ListTile(
                        leading: product['url_imagen'] != null && product['url_imagen'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product['url_imagen'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.shopping_bag, color: Colors.orange),
                        title: Text(normalizeText(product['nombre'] ?? 'Sin nombre')),
                        subtitle: Text(
                          'Tienda: ${normalizeText(tienda['nombre'] ?? 'Sin nombre')}',
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '\$${double.parse(product['precio'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          // Navigate to product detail or handle product selection
                          widget.onSearch(product['nombre']);
                          _focusNode.unfocus();
                          setState(() => _showResults = false);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}