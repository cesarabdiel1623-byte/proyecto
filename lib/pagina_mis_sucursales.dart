
// lib/pagina_mis_sucursales.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_editar_sucursal.dart'; // El formulario
import 'pagina_sucursales.dart'; // Para la clase Sucursal

class PaginaMisSucursales extends StatefulWidget {
  @override
  _PaginaMisSucursalesState createState() => _PaginaMisSucursalesState();
}

class _PaginaMisSucursalesState extends State<PaginaMisSucursales> {
  late Future<List<Sucursal>> _futureSucursales;

  @override
  void initState() {
    super.initState();
    _futureSucursales = _cargarSucursales();
  }

  Future<List<Sucursal>> _cargarSucursales() async {
    final negocioId = await _getNegocioId();
    final sucursalesData = await supabase
        .from('sucursales')
        .select()
        .eq('negocio_id', negocioId)
        .order('nombre', ascending: true);
    return sucursalesData.map((map) => Sucursal.fromMap(map)).toList();
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

  Future<void> _navegarAEditar([Sucursal? sucursal]) async {
    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaginaEditarSucursal(sucursal: sucursal),
      ),
    ) ?? false;

    if (huboCambios) {
      setState(() {
        _futureSucursales = _cargarSucursales();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Sucursales'),
      ),
      body: FutureBuilder<List<Sucursal>>(
        future: _futureSucursales,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aún no has añadido ninguna sucursal.'));
          }

          final sucursales = snapshot.data!;
          return ListView.builder(
            itemCount: sucursales.length,
            itemBuilder: (context, index) {
              final sucursal = sucursales[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.store)),
                  title: Text(sucursal.nombre),
                  subtitle: Text(sucursal.direccion),
                  trailing: Icon(Icons.edit),
                  onTap: () => _navegarAEditar(sucursal),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _navegarAEditar(),
      ),
    );
  }
}