// lib/pagina_editar_empleado.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase

class PaginaEditarEmpleado extends StatefulWidget {
  // Por ahora solo creamos, en el futuro podemos pasar un 'empleado' para editar
  PaginaEditarEmpleado();

  @override
  _PaginaEditarEmpleadoState createState() => _PaginaEditarEmpleadoState();
}

class _PaginaEditarEmpleadoState extends State<PaginaEditarEmpleado> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();

  Future<void> _guardarEmpleado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Obtenemos el negocio_id del usuario logueado
      final negocioId = (await supabase
          .from('usuarios_perfiles')
          .select('negocio_id')
          .eq('id', supabase.auth.currentUser!.id)
          .single())['negocio_id'];

      if (negocioId == null) {
        throw Exception('Usuario no vinculado a un negocio.');
      }
      
      // 2. Preparamos los datos
      final datos = {
        'nombre': _nombreController.text,
        'especialidad': _especialidadController.text,
        'negocio_id': negocioId,
        // Asignamos la primera sucursal por defecto (esto se puede mejorar)
        'sucursal_id': 1 
      };

      // 3. 'upsert' hace un INSERT
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
      body: Form(
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