// lib/pagina_mis_empleados.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_editar_empleado.dart';
import 'pagina_detalle_empleado.dart'; // <-- 1. Importamos la nueva página de detalles

// --- Clase Empleado (Actualizada para incluir sucursal) ---
class Empleado {
  final int id;
  final String nombre;
  final String especialidad;
  final String sucursalNombre;

  Empleado({
    required this.id, 
    required this.nombre, 
    required this.especialidad,
    required this.sucursalNombre
  });

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id'],
      nombre: map['nombre'] ?? 'Sin nombre',
      especialidad: map['especialidad'] ?? 'Sin especialidad',
      sucursalNombre: (map['sucursales'] != null) 
        ? map['sucursales']['nombre'] 
        : 'Sin sucursal',
    );
  }
}

class PaginaMisEmpleados extends StatefulWidget {
  @override
  _PaginaMisEmpleadosState createState() => _PaginaMisEmpleadosState();
}

class _PaginaMisEmpleadosState extends State<PaginaMisEmpleados> {
  late final Stream<List<Empleado>> _streamEmpleados;

  Future<String> _getNegocioId() async {
    // (Esta función es para obtener el ID del negocio del dueño)
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final data = await supabase
        .from('usuarios_perfiles')
        .select('negocio_id')
        .eq('id', user.id)
        .single();
    if (data['negocio_id'] == null) {
      throw Exception('Este usuario no está vinculado a un negocio.');
    }
    return data['negocio_id'] as String;
  }

  @override
  void initState() {
    super.initState();
    // Escuchamos la tabla 'empleados' en tiempo real
    _streamEmpleados = supabase
        .from('empleados')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final negocioId = await _getNegocioId();
          // Hacemos "join" para obtener el nombre de la sucursal
          final empleadosData = await supabase
              .from('empleados')
              .select('*, sucursales(nombre)') 
              .eq('negocio_id', negocioId);
          return empleadosData.map((map) => Empleado.fromMap(map)).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Empleados'),
      ),
      body: StreamBuilder<List<Empleado>>(
        stream: _streamEmpleados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aún no has añadido ningún empleado.'));
          }

          final empleados = snapshot.data!;
          return ListView.builder(
            itemCount: empleados.length,
            itemBuilder: (context, index) {
              final empleado = empleados[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text(empleado.nombre),
                  subtitle: Text('${empleado.especialidad} - ${empleado.sucursalNombre}'),
                  trailing: Icon(Icons.chevron_right),
                  
                  // --- 2. ¡CAMBIO IMPORTANTE AQUÍ! ---
                  // Hacemos que el 'onTap' lleve a la página de detalles
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaginaDetalleEmpleado(empleado: empleado),
                      ),
                    );
                  },

                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaEditarEmpleado(),
            ),
          );
        },
      ),
    );
  }
}