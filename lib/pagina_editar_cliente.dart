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
  
  // Este es el ID del chat de Telegram/Whatsapp. 
  // Si es manual, podemos inventar uno.
  late final TextEditingController _chatIdController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre);
    _telefonoController = TextEditingController(text: widget.cliente?.telefono);
    _chatIdController = TextEditingController(
      // Si es un cliente manual, su chat_id puede ser su teléfono
      text: widget.cliente?.chat_id ?? ''
    );
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final chatID = _chatIdController.text.isNotEmpty 
          ? _chatIdController.text 
          : _telefonoController.text; // Usamos el tel. como ID si está vacío

      final datos = {
        'nombre': _nombreController.text,
        'telefono': _telefonoController.text,
        'chat_id': chatID,
        'plataforma': widget.cliente?.plataforma ?? 'manual',
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
      setState(() => _isLoading = false);
    }
  }

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
            // Este campo es 'opcional' para el usuario, 
            // lo manejamos internamente.
            if (widget.cliente != null) // Solo mostar si editamos
              TextFormField(
                controller: _chatIdController,
                decoration: InputDecoration(labelText: 'ID de Chat (Telegram/WA)'),
                enabled: false,
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