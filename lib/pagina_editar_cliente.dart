// lib/pagina_editar_cliente.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_mis_clientes.dart'; // Para la clase ClienteBot

class PaginaEditarCliente extends StatefulWidget {
  final ClienteBot? cliente;
  PaginaEditarCliente({this.cliente});

  @override
  _PaginaEditarClienteState createState() => _PaginaEditarClienteState();
}

class _PaginaEditarClienteState extends State<PaginaEditarCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _chatIdController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre);
    _telefonoController = TextEditingController(text: widget.cliente?.telefono);
    _chatIdController = TextEditingController(
      text: widget.cliente?.chat_id ?? ''
    );
  }

  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
  Future<void> _guardarCliente() async {
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
      
      final chatID = _chatIdController.text.isNotEmpty 
          ? _chatIdController.text 
          // Si es manual y no hay ID, usamos el teléfono como ID único
          : _telefonoController.text; 

      final datos = {
        'nombre': _nombreController.text,
        'telefono': _telefonoController.text,
        'chat_id': chatID,
        'plataforma': widget.cliente?.plataforma ?? 'manual',
        'negocio_id': negocioId, // <-- 2. AÑADIMOS EL NEGOCIO_ID
        if (widget.cliente != null) 'id': widget.cliente!.id,
      };

      await supabase.from('clientes_bot').upsert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Cliente guardado!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // --- FIN DE LA CORRECCIÓN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente == null ? 'Añadir Cliente' : 'Editar Cliente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre del Cliente'),
              validator: (val) => val!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            
            // Este campo solo es visible si estamos editando
            // un cliente que vino del bot (ej. Telegram)
            if (widget.cliente != null && widget.cliente!.plataforma != 'manual')
              TextFormField(
                controller: _chatIdController,
                decoration: InputDecoration(labelText: 'ID de Chat (Telegram/WA)'),
                enabled: false, // No se puede editar
              ),
              
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarCliente,
                    child: Text('Guardar Cliente'),
                  ),
          ],
        ),
      ),
    );
  }
}