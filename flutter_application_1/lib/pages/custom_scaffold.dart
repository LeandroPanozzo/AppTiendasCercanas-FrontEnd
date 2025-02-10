import 'package:flutter/material.dart';
import './filter_panel.dart';
import './NotificationBadge.dart';
import './location_display.dart';  // Add this import

class CustomScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final bool isLoggedIn;
  final Future<void> Function() onLogout;  // Changed from VoidCallback
  final PreferredSizeWidget? searchBar;
  final Function(Map<String, dynamic>)? onApplyFilters;
  final Map<String, dynamic>? currentFilters; // Añadir esta línea

  const CustomScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.isLoggedIn,
    required this.onLogout,
    this.searchBar,
    this.onApplyFilters,
    this.currentFilters, // Añadir esta línea
  }) : super(key: key);

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openFilterPanel() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
Widget build(BuildContext context) {
  final appBar = AppBar(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.isLoggedIn) 
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: LocationDisplay(),
          ),
      ],
    ),
    toolbarHeight: widget.isLoggedIn ? 80 : kToolbarHeight, // Ajusta la altura si hay LocationDisplay
    leading: Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
            },
          );
        },
      ),
      actions: [
        if (widget.isLoggedIn) const NotificationBadge(),
        if (widget.onApplyFilters != null)
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilterPanel,
          ),
      ],
      bottom: widget.searchBar,
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: appBar,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            if (!widget.isLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar Sesión'),
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Registrarse'),
                onTap: () => Navigator.pushNamed(context, '/register'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mi Perfil'),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_basket),
                title: const Text('Mis Reservas'),
                onTap: () => Navigator.pushNamed(context, '/mis_reservas'),
              ),
              ListTile(
                leading: const Icon(Icons.store_mall_directory),
                title: const Text('Registrar tiendas'),
                onTap: () => Navigator.pushNamed(context, '/registrar_tiendas'),
              ),
              ListTile(
                leading: const Icon(Icons.store_mall_directory_sharp),
                title: const Text('Mis Tiendas'),
                onTap: () => Navigator.pushNamed(context, '/mis_tiendas'),
              ),
             ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await widget.onLogout(); // Esperar a que termine el logout
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              },
            ),
            ],
          ],
        ),
      ),
      endDrawer: widget.onApplyFilters != null
          ? FilterPanel(
              onApplyFilters: widget.onApplyFilters!,
              onClose: () => Navigator.pop(context),
              currentFilters: widget.currentFilters,
            )
          : null,
      body: widget.body,
    );
  }
}