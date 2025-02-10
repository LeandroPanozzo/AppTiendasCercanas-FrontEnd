import 'package:flutter/material.dart';
import 'dart:convert';
import '../api_service.dart';
import '../profile_service.dart';
import './TiendaProductosPage.dart';

class PaymentMethodStoresPage extends StatefulWidget {
  final String paymentMethod;

  const PaymentMethodStoresPage({
    Key? key,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  _PaymentMethodStoresPageState createState() => _PaymentMethodStoresPageState();
}

class _PaymentMethodStoresPageState extends State<PaymentMethodStoresPage> {
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
    _fetchStoresByPaymentMethod();
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

  Future<void> _fetchStoresByPaymentMethod() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final paymentMethodMap = {
        'efectivo': 'efectivo',
        'debito': 'debito',
        'credito': 'credito',
        'transferencia_bancaria': 'transferencia_bancaria',
        'pago_movil': 'pago_movil',
        'qr': 'qr',
        'monedero_electronico': 'monedero_electronico',
        'criptomoneda': 'criptomoneda',
        'pasarela_en_linea': 'pasarela_en_linea',
        'cheque': 'cheque',
        'pagos_a_plazos': 'pagos_a_plazos',
        'vales': 'vales',
        'contra_entrega': 'contra_entrega',
        'debito_directo': 'debito_directo',
        'creditos_internos': 'creditos_internos'
      };

      final apiFieldName = paymentMethodMap[widget.paymentMethod];

      if (apiFieldName == null) {
        throw Exception('Método de pago no reconocido: ${widget.paymentMethod}');
      }

      final city = await ProfileService().getCity();
      final response = await ApiService.fetchStoresByPaymentMethod(
        apiFieldName, 
        city,
        page: currentPage,
        limit: storesPerPage,
      );

      setState(() {
        stores = response;
        isLoading = false;
        hasMoreStores = response.length >= storesPerPage;
      });

      print('Stores fetched for ${widget.paymentMethod} in $city: ${stores.length}');
    } catch (e) {
      setState(() {
        errorMessage = normalizeText(e.toString());
        isLoading = false;
      });
      print('Error fetching stores: $e');
    }
  }

  Future<void> _loadMoreStores() async {
    if (isLoadingMore) return;

    try {
      setState(() {
        isLoadingMore = true;
      });

      final paymentMethodMap = {
        'efectivo': 'efectivo',
        'debito': 'debito',
        'credito': 'credito',
        'transferencia_bancaria': 'transferencia_bancaria',
        'pago_movil': 'pago_movil',
        'qr': 'qr',
        'monedero_electronico': 'monedero_electronico',
        'criptomoneda': 'criptomoneda',
        'pasarela_en_linea': 'pasarela_en_linea',
        'cheque': 'cheque',
        'pagos_a_plazos': 'pagos_a_plazos',
        'vales': 'vales',
        'contra_entrega': 'contra_entrega',
        'debito_directo': 'debito_directo',
        'creditos_internos': 'creditos_internos'
      };

      final apiFieldName = paymentMethodMap[widget.paymentMethod];
      final city = await ProfileService().getCity();
      final nextPage = currentPage + 1;
      
      final moreStores = await ApiService.fetchStoresByPaymentMethod(
        apiFieldName!,
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
      print('Error loading more stores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tiendas con ${widget.paymentMethod}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : stores.isEmpty
                  ? const Center(child: Text('No se encontraron tiendas'))
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