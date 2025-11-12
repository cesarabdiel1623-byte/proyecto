// lib/pagina_mis_servicios.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_editar_servicio.dart';

// --- Creamos una clase para el Servicio ---
class Servicio {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracion;

  Servicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracion,
  });

  factory Servicio.fromMap(Map<String, dynamic> map) {
    return Servicio(
      id: map['id'],
      nombre: map['nombre'] ?? 'Sin nombre',
      descripcion: map['descripcion'] ?? 'Sin descripción',
      precio: (map['precio_base'] as num).toDouble(),
      duracion: map['duracion_aprox_minutos'] ?? 0,
    );
  }
}

class PaginaMisServicios extends StatefulWidget {
  @override
  _PaginaMisServiciosState createState() => _PaginaMisServiciosState();
}

class _PaginaMisServiciosState extends State<PaginaMisServicios> {
  // Usamos un StreamBuilder para que la lista se actualice sola
  late final Stream<List<Servicio>> _streamServicios;

  // --- CORRECCIÓN 1: La función ahora devuelve un 'String' ---
  Future<String> _getNegocioId() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final data = await supabase
        .from('usuarios_perfiles')
        .select('negocio_id')
        .eq('id', user.id)
        .single();
    if (data['negocio_id'] == null) {
      throw Exception('Este usuario no está vinculado a un negocio.');
    }
    
    // --- CORRECCIÓN 2: Devolvemos el 'negocio_id' como un 'String' ---
    return data['negocio_id'] as String; 
  }

  @override
  void initState() {
    super.initState();
    // Inicializamos el stream
    _streamServicios = supabase
        .from('servicios')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          // Esta parte ya funciona bien porque _getNegocioId() devuelve un String
          final negocioId = await _getNegocioId(); 
          final serviciosData = await supabase
              .from('servicios')
              .select()
              .eq('negocio_id', negocioId); // Supabase puede comparar el UUID con un String
          return serviciosData.map((map) => Servicio.fromMap(map)).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Servicios'),
      ),
      body: StreamBuilder<List<Servicio>>(
        stream: _streamServicios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aún no has añadido ningún servicio.'));
          }

          final servicios = snapshot.data!;

          return ListView.builder(
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              final servicio = servicios[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text(servicio.nombre),
                  subtitle: Text('${servicio.duracion} min - \$${servicio.precio.toStringAsFixed(2)}'),
                  trailing: Icon(Icons.edit),
                  onTap: () {
                    // Navega a la página de edición (Modo Edición)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaginaEditarServicio(servicio: servicio),
                      ),
                    ).then((value) {
                      // Opcional: Refrescar la lista cuando volvemos
                      setState(() {});
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      // Botón para AÑADIR un nuevo servicio
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navega a la página de edición (Modo Creación)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaEditarServicio(servicio: null),
            ),
          ).then((value) {
            // Opcional: Refrescar la lista cuando volvemos
            setState(() {});
          });
        },
      ),
    );
  }
}