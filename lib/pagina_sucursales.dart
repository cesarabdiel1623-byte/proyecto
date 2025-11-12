// lib/pagina_sucursales.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para usar 'supabase'
import 'pagina_detalle_sucursal.dart'; // Importamos la página de detalles

// --- Creamos una "clase" para manejar los datos de la sucursal ---
class Sucursal {
  final int id;
  final String nombre;
  final String direccion;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
  });

  // Un constructor que convierte el "mapa" de Supabase a nuestra clase
  factory Sucursal.fromMap(Map<String, dynamic> map) {
    return Sucursal(
      id: map['id'],
      nombre: map['nombre'],
      direccion: map['direccion'],
    );
  }
}

// --- Esta es la nueva PaginaSucursales ---
class PaginaSucursales extends StatefulWidget {
  @override
  _PaginaSucursalesState createState() => _PaginaSucursalesState();
}

class _PaginaSucursalesState extends State<PaginaSucursales> {
  // Creamos un "Future" para guardar la lista de sucursales
  late final Future<List<Sucursal>> _futureSucursales;

  @override
  void initState() {
    super.initState();
    // Cuando la página cargue, mandamos a buscar las sucursales
    _futureSucursales = _getSucursales();
  }

  // --- Función que habla con Supabase ---
  Future<List<Sucursal>> _getSucursales() async {
    try {
      // 1. Pedimos la tabla 'sucursales'
      final data = await supabase.from('sucursales').select();

      // 2. Convertimos la lista de mapas (List<Map>) a una lista de nuestra clase (List<Sucursal>)
      final sucursales = data.map((map) => Sucursal.fromMap(map)).toList();
      return sucursales;
      
    } catch (e) {
      // Si algo sale mal, mostramos el error
      if (mounted) { // Verificación de 'mounted'
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar sucursales: $e'),
          backgroundColor: Colors.red,
        ));
      }
      return []; // Devolvemos una lista vacía
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sucursales Disponibles'),
        // El botón de logout se quitó correctamente
      ),
      // FutureBuilder espera a que lleguen los datos de Supabase
      body: FutureBuilder<List<Sucursal>>(
        future: _futureSucursales,
        builder: (context, snapshot) {
          
          // --- MIENTRAS CARGA ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // --- SI HUBO UN ERROR ---
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // --- SI NO LLEGARON DATOS ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No se encontraron sucursales.'));
          }

          // --- ¡TENEMOS DATOS! ---
          final sucursales = snapshot.data!;
          
          // Mostramos los datos en una ListView
          return ListView.builder(
            itemCount: sucursales.length,
            itemBuilder: (context, index) {
              final sucursal = sucursales[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(Icons.store_mall_directory),
                  title: Text(sucursal.nombre),
                  subtitle: Text(sucursal.direccion),
                  
                  // --- ESTA ES LA ADAPTACIÓN ---
                  // (Reemplazamos el print por la navegación)
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaginaDetalleSucursal(sucursal: sucursal),
                      ),
                    );
                  },

                ),
              );
            },
          );
        },
      ),
    );
  }
}