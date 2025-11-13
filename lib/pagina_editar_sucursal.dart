// lib/pagina_editar_sucursal.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
// Importamos esto para la clase "Sucursal" (veo que aún tienes el archivo)
import 'pagina_sucursales.dart'; 

class PaginaEditarSucursal extends StatefulWidget {
  // Si 'sucursal' es null = Modo Creación
  // Si 'sucursal' tiene datos = Modo Edición
  final Sucursal? sucursal;

  PaginaEditarSucursal({this.sucursal});

  @override
  _PaginaEditarSucursalState createState() => _PaginaEditarSucursalState();
}

class _PaginaEditarSucursalState extends State<PaginaEditarSucursal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;

  @override
  void initState() {
    super.initState();
    // Llenamos los campos si estamos editando
    _nombreController = TextEditingController(text: widget.sucursal?.nombre);
    _direccionController = TextEditingController(text: widget.sucursal?.direccion);
  }

  Future<void> _guardarSucursal() async {
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
        'direccion': _direccionController.text,
        'negocio_id': negocioId,
        // Si estamos editando, usamos el ID existente
        if (widget.sucursal != null) 'id': widget.sucursal!.id,
      };

      // 3. 'upsert' hace un INSERT o un UPDATE automáticamente
      await supabase.from('sucursales').upsert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Sucursal ${widget.sucursal == null ? 'guardada' : 'actualizada'} con éxito!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Regresa a la lista
      }
    
    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
    // Reemplazamos 'mostrarError' por el código correcto
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    // --- FIN DE LA CORRECCIÓN ---

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sucursal == null ? 'Añadir Sucursal' : 'Editar Sucursal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre de la Sucursal'),
              validator: (val) => val!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _direccionController,
              decoration: InputDecoration(labelText: 'Dirección'),
              validator: (val) => val!.isEmpty ? 'La dirección es obligatoria' : null,
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarSucursal,
                    child: Text('Guardar Sucursal'),
                  ),
          ],
        ),
      ),
    );
  }
}