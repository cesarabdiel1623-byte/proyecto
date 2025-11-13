// lib/pagina_editar_empleado.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_mis_empleados.dart'; // Para la clase Empleado

// --- Clase para manejar las sucursales ---
class SucursalSimple {
  final int id;
  final String nombre;
  SucursalSimple({required this.id, required this.nombre});
}

class PaginaEditarEmpleado extends StatefulWidget {
  final Empleado? empleado; // <-- AÑADIDO: Para recibir el empleado a editar

  PaginaEditarEmpleado({this.empleado}); // Constructor actualizado

  @override
  _PaginaEditarEmpleadoState createState() => _PaginaEditarEmpleadoState();
}

class _PaginaEditarEmpleadoState extends State<PaginaEditarEmpleado> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get _esModoEdicion => widget.empleado != null; // Para saber si editamos

  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();

  List<SucursalSimple> _listaSucursales = [];
  int? _sucursalSeleccionadaId;
  bool _cargandoSucursales = true;
  String? _negocioId;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, llenamos los campos iniciales
    if (_esModoEdicion) {
      _nombreController.text = widget.empleado!.nombre;
      _especialidadController.text = widget.empleado!.especialidad;
    }
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoSucursales = true);
    try {
      _negocioId = (await supabase
          .from('usuarios_perfiles')
          .select('negocio_id')
          .eq('id', supabase.auth.currentUser!.id)
          .single())['negocio_id'];

      if (_negocioId == null) throw Exception('Usuario no vinculado a un negocio.');

      final data = await supabase
          .from('sucursales')
          .select('id, nombre')
          .eq('negocio_id', _negocioId!);
          
      _listaSucursales = data
          .map((item) => SucursalSimple(id: item['id'], nombre: item['nombre']))
          .toList();

      // Si estamos editando, intentamos pre-seleccionar su sucursal
      if (_esModoEdicion) {
        // Buscamos el ID de la sucursal por su nombre
        final sucursalDelEmpleado = _listaSucursales.firstWhere(
          (s) => s.nombre == widget.empleado!.sucursalNombre,
          orElse: () => _listaSucursales.isNotEmpty ? _listaSucursales.first : SucursalSimple(id: -1, nombre: ''),
        );
        if (sucursalDelEmpleado.id != -1) {
          _sucursalSeleccionadaId = sucursalDelEmpleado.id;
        }
      } else if (_listaSucursales.length == 1) {
        _sucursalSeleccionadaId = _listaSucursales[0].id;
      }

    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      if (mounted) setState(() => _cargandoSucursales = false);
    }
  }

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate() || _sucursalSeleccionadaId == null) {
      if (_sucursalSeleccionadaId == null) _mostrarError('Por favor, selecciona una sucursal.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final datos = {
        'nombre': _nombreController.text,
        'especialidad': _especialidadController.text,
        'negocio_id': _negocioId,
        'sucursal_id': _sucursalSeleccionadaId,
      };
      // Si es modo edición, añadimos el ID para que Supabase sepa cuál actualizar
      if (_esModoEdicion) {
        datos['id'] = widget.empleado!.id;
      }

      await supabase.from('empleados').upsert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Empleado ${_esModoEdicion ? 'actualizado' : 'guardado'}!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true); // Regresa a la lista y avisa que hubo cambios
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarEmpleado() async {
    if (!_esModoEdicion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar a ${widget.empleado!.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await supabase.from('empleados').delete().eq('id', widget.empleado!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Empleado eliminado'),
            backgroundColor: Colors.orange,
          ));
          Navigator.pop(context, true); // Regresa y avisa que hubo cambios
        }
      } catch (e) {
        _mostrarError('Error al eliminar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esModoEdicion ? 'Editar Empleado' : 'Añadir Empleado'),
        actions: [
          if (_esModoEdicion) // Mostramos el botón de borrar solo en modo edición
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _eliminarEmpleado,
            ),
        ],
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
                          child: Text(_esModoEdicion ? 'Guardar Cambios' : 'Crear Empleado'),
                        ),
                ],
              ),
            ),
    );
  }
}