// lib/pagina_editar_empleado.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase

// --- Clase para manejar las sucursales ---
class SucursalSimple {
  final int id;
  final String nombre;
  SucursalSimple({required this.id, required this.nombre});
}

class PaginaEditarEmpleado extends StatefulWidget {
  PaginaEditarEmpleado();

  @override
  _PaginaEditarEmpleadoState createState() => _PaginaEditarEmpleadoState();
}

class _PaginaEditarEmpleadoState extends State<PaginaEditarEmpleado> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();

  // --- NUEVAS VARIABLES PARA EL DROPDOWN ---
  List<SucursalSimple> _listaSucursales = [];
  int? _sucursalSeleccionadaId;
  bool _cargandoSucursales = true;
  String? _negocioId;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      // 1. Obtenemos el negocio_id del usuario logueado
      _negocioId = (await supabase
          .from('usuarios_perfiles')
          .select('negocio_id')
          .eq('id', supabase.auth.currentUser!.id)
          .single())['negocio_id'];

      if (_negocioId == null) {
        throw Exception('Usuario no vinculado a un negocio.');
      }
      
      // 2. Buscamos las sucursales de ESE negocio
      final data = await supabase
          .from('sucursales')
          .select('id, nombre')
          .eq('negocio_id', _negocioId!);
          
      _listaSucursales = data
          .map((item) => SucursalSimple(id: item['id'], nombre: item['nombre']))
          .toList();

      // 3. Si solo hay una sucursal, la seleccionamos por defecto
      if (_listaSucursales.length == 1) {
        _sucursalSeleccionadaId = _listaSucursales[0].id;
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar sucursales: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _cargandoSucursales = false);
    }
  }

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate()) return;
    // Validamos que se haya seleccionado una sucursal
    if (_sucursalSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, selecciona una sucursal.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final datos = {
        'nombre': _nombreController.text,
        'especialidad': _especialidadController.text,
        'negocio_id': _negocioId,
        'sucursal_id': _sucursalSeleccionadaId, // ¡Usamos el ID seleccionado!
      };

      await supabase.from('empleados').upsert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Empleado guardado!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Regresa a la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Empleado'),
      ),
      body: _cargandoSucursales
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(labelText: 'Nombre del Empleado'),
                    validator: (val) => val!.isEmpty ? 'El nombre es obligatorio' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _especialidadController,
                    decoration: InputDecoration(labelText: 'Especialidad (ej: Barbero)'),
                    validator: (val) => val!.isEmpty ? 'La especialidad es obligatoria' : null,
                  ),
                  SizedBox(height: 12),
                  
                  // --- NUEVO DROPDOWN DE SUCURSAL ---
                  DropdownButtonFormField<int>(
                    value: _sucursalSeleccionadaId,
                    decoration: InputDecoration(labelText: 'Sucursal'),
                    hint: Text('Selecciona una sucursal'),
                    items: _listaSucursales.map((sucursal) {
                      return DropdownMenuItem(
                        value: sucursal.id,
                        child: Text(sucursal.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _sucursalSeleccionadaId = value);
                    },
                    validator: (val) => val == null ? 'La sucursal es obligatoria' : null,
                  ),
                  
                  SizedBox(height: 24),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _guardarEmpleado,
                          child: Text('Guardar Empleado'),
                        ),
                ],
              ),
            ),
    );
  }
}