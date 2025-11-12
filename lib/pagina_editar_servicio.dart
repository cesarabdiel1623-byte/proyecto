// lib/pagina_editar_servicio.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_mis_servicios.dart'; // Para la clase Servicio

class PaginaEditarServicio extends StatefulWidget {
  // Si 'servicio' es null, es una página de "Crear Nuevo"
  // Si 'servicio' tiene datos, es una página de "Editar"
  final Servicio? servicio;

  PaginaEditarServicio({this.servicio});

  @override
  _PaginaEditarServicioState createState() => _PaginaEditarServicioState();
}

class _PaginaEditarServicioState extends State<PaginaEditarServicio> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los campos del formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _descController;
  late final TextEditingController _precioController;
  late final TextEditingController _duracionController;

  @override
  void initState() {
    super.initState();
    // Llenamos los campos si estamos editando
    _nombreController = TextEditingController(text: widget.servicio?.nombre);
    _descController = TextEditingController(text: widget.servicio?.descripcion);
    _precioController = TextEditingController(text: widget.servicio?.precio.toString());
    _duracionController = TextEditingController(text: widget.servicio?.duracion.toString());
  }

  Future<void> _guardarServicio() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hace nada
    }
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
      
      // 2. Preparamos los datos para Supabase
      final datos = {
        'nombre': _nombreController.text,
        'descripcion': _descController.text,
        'precio_base': double.parse(_precioController.text),
        'duracion_aprox_minutos': int.parse(_duracionController.text),
        'negocio_id': negocioId,
        // Si estamos editando, usamos el ID existente
        if (widget.servicio != null) 'id': widget.servicio!.id,
      };

      // 3. 'upsert' hace un INSERT o un UPDATE automáticamente
      await supabase.from('servicios').upsert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Servicio guardado con éxito!'),
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
        // Título dinámico
        title: Text(widget.servicio == null ? 'Añadir Servicio' : 'Editar Servicio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre del Servicio'),
              validator: (val) => val!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _precioController,
              decoration: InputDecoration(labelText: 'Precio (ej: 150.00)'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              validator: (val) => val!.isEmpty ? 'El precio es obligatorio' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _duracionController,
              decoration: InputDecoration(labelText: 'Duración (en minutos, ej: 30)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (val) => val!.isEmpty ? 'La duración es obligatoria' : null,
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarServicio,
                    child: Text('Guardar Servicio'),
                  ),
          ],
        ),
      ),
    );
  }
}