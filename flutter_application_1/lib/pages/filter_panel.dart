import 'package:flutter/material.dart';

class FilterPanel extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final VoidCallback onClose;
  final Map<String, dynamic>? currentFilters;

  const FilterPanel({
    Key? key,
    required this.onApplyFilters,
    required this.onClose,
    this.currentFilters,
  }) : super(key: key);

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late bool _isService;
  late bool _isReservable;
  late bool _hasDiscount;
  late bool _hasPromotion;
  late List<String> _selectedPaymentMethods;
  late String? _selectedCategory;

  // Payment methods from your Django choices
  final List<Map<String, String>> paymentMethods = [
    {"value": "efectivo", "label": "Efectivo"},
    {"value": "debito", "label": "Débito"},
    {"value": "credito", "label": "Crédito"},
    {"value": "transferencia_bancaria", "label": "Transferencia Bancaria"},
    {"value": "pago_movil", "label": "Pago Móvil"},
    {"value": "qr", "label": "Código QR"},
    {"value": "monedero_electronico", "label": "Monedero Electrónico"},
    {"value": "criptomoneda", "label": "Criptomoneda"},
    {"value": "pasarela_en_linea", "label": "Pasarela de Pago en Línea"},
    {"value": "cheque", "label": "Cheque"},
    {"value": "pagos_a_plazos", "label": "Pagos a Plazos"},
    {"value": "vales", "label": "Vales/Tarjetas de Regalo"},
    {"value": "contra_entrega", "label": "Pago contra Entrega"},
    {"value": "debito_directo", "label": "Débito Directo"},
    {"value": "creditos_internos", "label": "Créditos Internos/Monedas Virtuales"},
  ];

  // Categories from your Django choices
  final List<Map<String, String>> categories = [
    {"value": "restaurante", "label": "Restaurante"},
    {"value": "supermercado", "label": "Supermercado"},
    {"value": "ropa", "label": "Ropa"},
    {"value": "tecnologia", "label": "Tecnología"},
    {"value": "belleza", "label": "Belleza"},
    {"value": "deportes", "label": "Deportes"},
    {"value": "veterinaria", "label": "Veterinaria"},
    {"value": "salud", "label": "Salud"},
    {"value": "autopartes", "label": "Autopartes"},
    {"value": "construccion_y_ferreteria", "label": "Construcción y Ferretería"},
    {"value": "polirubro", "label": "Polirubro"},
    {"value": "otros", "label": "Otros"},
  ];

  @override
  void initState() {
    super.initState();
    final currentFilters = widget.currentFilters;
    if (currentFilters != null) {
      final priceRange = currentFilters['priceRange'] as RangeValues;
      _minPriceController = TextEditingController(text: priceRange.start.toString());
      _maxPriceController = TextEditingController(text: priceRange.end.toString());
      _isService = currentFilters['isService'] as bool;
      _isReservable = currentFilters['isReservable'] as bool;
      _hasDiscount = currentFilters['hasDiscount'] as bool;
      _hasPromotion = currentFilters['hasPromotion'] as bool;
      _selectedPaymentMethods = List<String>.from(currentFilters['paymentMethods'] ?? []);
      _selectedCategory = currentFilters['category'] as String?;
    } else {
      _minPriceController = TextEditingController(text: '0');
      _maxPriceController = TextEditingController(text: '1000');
      _isService = false;
      _isReservable = false;
      _hasDiscount = false;
      _hasPromotion = false;
      _selectedPaymentMethods = [];
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }
    if (double.tryParse(value) == null) {
      return 'Ingrese un número válido';
    }
    return null;
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Métodos de Pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: paymentMethods.map((method) {
            return FilterChip(
              label: Text(method['label']!),
              selected: _selectedPaymentMethods.contains(method['value']),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedPaymentMethods.add(method['value']!);
                  } else {
                    _selectedPaymentMethods.remove(method['value']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Categoría',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Seleccionar categoría'),
          isExpanded: true,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category['value'],
              child: Text(category['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Rango de Precio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio Mínimo',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio Máximo',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
                _buildPaymentMethodsSection(),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Servicios'),
                  value: _isService,
                  onChanged: (bool value) {
                    setState(() {
                      _isService = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Permite Reservas'),
                  value: _isReservable,
                  onChanged: (bool value) {
                    setState(() {
                      _isReservable = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Con Descuento'),
                  value: _hasDiscount,
                  onChanged: (bool value) {
                    setState(() {
                      _hasDiscount = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Con Promociones'),
                  subtitle: const Text('Incluye promociones NxM y descuentos por unidad'),
                  value: _hasPromotion,
                  onChanged: (bool value) {
                    setState(() {
                      _hasPromotion = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _minPriceController.text = '0';
                        _maxPriceController.text = '1000';
                        _isService = false;
                        _isReservable = false;
                        _hasDiscount = false;
                        _hasPromotion = false;
                        _selectedPaymentMethods = [];
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final minPrice = double.tryParse(_minPriceController.text) ?? 0;
                      final maxPrice = double.tryParse(_maxPriceController.text) ?? 1000;
                      
                      final filters = {
                        'priceRange': RangeValues(minPrice, maxPrice),
                        'isService': _isService,
                        'isReservable': _isReservable,
                        'hasDiscount': _hasDiscount,
                        'hasPromotion': _hasPromotion,
                        'paymentMethods': _selectedPaymentMethods,
                        'category': _selectedCategory,
                      };
                      widget.onApplyFilters(filters);
                      widget.onClose();
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}