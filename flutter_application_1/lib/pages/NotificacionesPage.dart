import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import 'package:intl/intl.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({Key? key}) : super(key: key);

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> with TickerProviderStateMixin {
  List<dynamic> notificaciones = [];
  bool isLoading = true;
  late AnimationController _refreshIconController;

  @override
  void initState() {
    super.initState();
    _refreshIconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    cargarNotificaciones();
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  Future<void> cargarNotificaciones() async {
    setState(() => isLoading = true);
    _refreshIconController.repeat();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/notificaciones/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notificaciones = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al cargar las notificaciones'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    _refreshIconController.stop();
  }

  Future<void> marcarComoLeida(int notificacionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/notificaciones/$notificacionId/leida/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notificaciones.removeWhere((notif) => notif['id'] == notificacionId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al marcar la notificación como leída'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> mostrarDialogoConfirmacion(int notificacionId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirmar acción'),
            ],
          ),
          content: const Text(
            '¿Deseas marcar esta notificación como leída?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
                marcarComoLeida(notificacionId);
              },
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    );
  }

  String formatearFecha(String fecha) {
    final DateTime dateTime = DateTime.parse(fecha);
    final DateFormat formatter = DateFormat('d MMM y', 'es');
    return formatter.format(dateTime);
  }

  Color getNotificationColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'nueva_reserva':
        return Colors.blue.shade100;
      case 'reserva_retirada':
        return Colors.green.shade100;
      case 'reserva_cancelada':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  IconData getNotificationIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'nueva_reserva':
        return Icons.shopping_cart;
      case 'reserva_retirada':
        return Icons.check_circle;
      case 'reserva_cancelada':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
              child: const Icon(Icons.refresh),
            ),
            onPressed: cargarNotificaciones,
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : notificaciones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes notificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: notificaciones.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final notificacion = notificaciones[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Dismissible(
                          key: Key(notificacion['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            await mostrarDialogoConfirmacion(notificacion['id']);
                            return false;
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: getNotificationColor(notificacion['tipo']),
                                child: Icon(
                                  getNotificationIcon(notificacion['tipo']),
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text(
                                notificacion['titulo'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notificacion['mensaje'],
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatearFecha(notificacion['fecha_creacion']),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => mostrarDialogoConfirmacion(notificacion['id']),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}