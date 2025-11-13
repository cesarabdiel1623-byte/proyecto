
// lib/pagina_mis_empleados.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_editar_empleado.dart';

// La clase Empleado ahora incluye 'sucursalNombre'
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
      sucursalNombre: (map['sucursales'] != null && map['sucursales']['nombre'] != null) 
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
  // Cambiamos a Future para poder recargarlo
  late Future<List<Empleado>> _futureEmpleados;

  @override
  void initState() {
    super.initState();
    _futureEmpleados = _cargarEmpleados();
  }

  Future<List<Empleado>> _cargarEmpleados() async {
    final negocioId = await _getNegocioId();
    final empleadosData = await supabase
        .from('empleados')
        .select('*, sucursales(nombre)')
        .eq('negocio_id', negocioId)
        .order('nombre', ascending: true);
        
    return empleadosData.map((map) => Empleado.fromMap(map)).toList();
  }

  Future<String> _getNegocioId() async {
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

  // --- Navegación y recarga ---
  Future<void> _navegarAEditar([Empleado? empleado]) async {
    // El '?? false' es por si el usuario simplemente desliza para atrás
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaEditarEmpleado(empleado: empleado),
      ),
    ) ?? false;

    // Si la página de edición nos dice que hubo cambios, recargamos la lista
    if (huboCambios) {
      setState(() {
        _futureEmpleados = _cargarEmpleados();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Empleados'),
      ),
      body: FutureBuilder<List<Empleado>>(
        future: _futureEmpleados,
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
                  trailing: Icon(Icons.edit), // Cambiado para reflejar la acción
                  onTap: () => _navegarAEditar(empleado), // Navega para editar
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _navegarAEditar(), // Navega para crear
      ),
    );
  }
}