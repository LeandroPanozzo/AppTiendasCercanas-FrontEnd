import 'package:flutter/material.dart';
import 'dart:convert';
import '../api_service.dart';
import '../profile_service.dart';
import './TiendaProductosPage.dart';

class CategoryStoresPage extends StatefulWidget {
  final String categoria;

  const CategoryStoresPage({Key? key, required this.categoria}) : super(key: key);

  @override
  _CategoryStoresPageState createState() => _CategoryStoresPageState();
}

class _CategoryStoresPageState extends State<CategoryStoresPage> {
  List<dynamic> stores = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  static const int storesPerPage = 10;
  bool hasMoreStores = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchStoresByCategory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoadingMore &&
        hasMoreStores) {
      _loadMoreStores();
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

  Future<void> _fetchStoresByCategory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final city = await ProfileService().getCity();
      final fetchedStores = await ApiService.fetchStoresByCategory(
        widget.categoria, 
        city,
        page: currentPage,
        limit: storesPerPage,
      );

      setState(() {
        stores = fetchedStores;
        isLoading = false;
        hasMoreStores = fetchedStores.length >= storesPerPage;
      });
    } catch (e) {
      setState(() {
        errorMessage = normalizeText(e.toString());
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stores: $errorMessage')),
      );
    }
  }

  Future<void> _loadMoreStores() async {
    if (isLoadingMore) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final city = await ProfileService().getCity();
      final nextPage = currentPage + 1;
      
      final moreStores = await ApiService.fetchStoresByCategory(
        widget.categoria,
        city,
        page: nextPage,
        limit: storesPerPage,
      );

      setState(() {
        stores.addAll(moreStores);
        currentPage = nextPage;
        isLoadingMore = false;
        hasMoreStores = moreStores.length >= storesPerPage;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more stores: ${normalizeText(e.toString())}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiendas de ${widget.categoria}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : stores.isEmpty
                  ? Center(child: Text('No hay tiendas en la categoría ${widget.categoria}'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: stores.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == stores.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final store = stores[index];
                        return ListTile(
                          leading: store['url_logo'] != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    normalizeText(store['url_logo']),
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.store),
                                ),
                          title: Text(
                            normalizeText(store['nombre']),
                          ),
                          subtitle: Text(
                            '${normalizeText(store['direccion_calle'])} ${normalizeText(store['direccion_numero'])}, ${normalizeText(store['ciudad'])}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TiendaProductosPage(
                                  tienda: store,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}