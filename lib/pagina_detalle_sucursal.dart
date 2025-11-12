// lib/pagina_detalle_sucursal.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para 'supabase'
import 'pagina_sucursales.dart'; // Para la clase 'Sucursal'

// --- Creamos una clase para el Servicio ---
class Servicio {
  final String nombre;
  final String descripcion;
  final double precio;

  Servicio({required this.nombre, required this.descripcion, required this.precio});

  factory Servicio.fromMap(Map<String, dynamic> map) {
    return Servicio(
      // 'servicios' es el nombre de la tabla de donde sacamos los detalles
      nombre: map['servicios']['nombre'] ?? 'Sin nombre',
      descripcion: map['servicios']['descripcion'] ?? 'Sin descripción',
      // 'precio_especifico' es de la tabla 'sucursal_servicios'
      precio: (map['precio_especifico'] as num).toDouble(),
    );
  }
}

class PaginaDetalleSucursal extends StatefulWidget {
  final Sucursal sucursal; // Recibimos la sucursal en la que se hizo clic

  PaginaDetalleSucursal({required this.sucursal});

  @override
  _PaginaDetalleSucursalState createState() => _PaginaDetalleSucursalState();
}

class _PaginaDetalleSucursalState extends State<PaginaDetalleSucursal> {
  late final Future<List<Servicio>> _futureServicios;

  @override
  void initState() {
    super.initState();
    _futureServicios = _getServicios();
  }

  // --- Función para buscar los servicios DE ESTA sucursal ---
  Future<List<Servicio>> _getServicios() async {
    try {
      // Hacemos una consulta "join"
      final data = await supabase
          .from('sucursal_servicios')
          // Pedimos el precio y, de la tabla 'servicios', su nombre y descripción
          .select('precio_especifico, servicios(nombre, descripcion)')
          .eq('sucursal_id', widget.sucursal.id); // Solo de esta sucursal

      final servicios = data.map((map) => Servicio.fromMap(map)).toList();
      return servicios;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar servicios: $e'),
        backgroundColor: Colors.red,
      ));
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sucursal.nombre), // Título con el nombre de la sucursal
      ),
      body: ListView(
        children: [
          // --- Sección de Información ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sucursal.nombre,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    // Usamos Expanded para que el texto no se desborde
                    Expanded(
                      child: Text(
                        widget.sucursal.direccion,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(thickness: 1, height: 20),

          // --- Sección de Servicios ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Servicios Disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // FutureBuilder para la lista de servicios
          FutureBuilder<List<Servicio>>(
            future: _futureServicios,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No hay servicios disponibles.'));
              }
              final servicios = snapshot.data!;

              // Usamos 'Column' en lugar de 'ListView' porque ya estamos dentro de un ListView
              return Column(
                children: servicios.map((servicio) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(servicio.nombre),
                      subtitle: Text(servicio.descripcion),
                      trailing: Text(
                        '\$${servicio.precio.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                      ),
                      onTap: () {
                        // Próximo paso: Agendar una cita para este servicio
                        print('Agendar ${servicio.nombre}');
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}