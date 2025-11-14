// lib/pagina_mis_clientes.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_editar_cliente.dart'; 

// --- Clase para el Cliente (CORREGIDA) ---
class ClienteBot {
  final int id;
  final String nombre;
  final String? telefono;
  final String plataforma;
  final String chat_id; // <-- 1. AÑADIMOS LA PROPIEDAD QUE FALTABA

  ClienteBot({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.plataforma,
    required this.chat_id, // <-- 2. LA AÑADIMOS AL CONSTRUCTOR
  });

  factory ClienteBot.fromMap(Map<String, dynamic> map) {
    return ClienteBot(
      id: map['id'],
      nombre: map['nombre'] ?? 'Sin nombre',
      telefono: map['telefono'],
      plataforma: map['plataforma'] ?? 'Desconocida',
      chat_id: map['chat_id'] ?? '', // <-- 3. LA LEEMOS DEL MAPA
    );
  }
}

class PaginaMisClientes extends StatefulWidget {
  @override
  _PaginaMisClientesState createState() => _PaginaMisClientesState();
}

class _PaginaMisClientesState extends State<PaginaMisClientes> {
  late final Stream<List<ClienteBot>> _streamClientes;

  @override
  void initState() {
    super.initState();
    _streamClientes = supabase
        .from('clientes_bot')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((map) => ClienteBot.fromMap(map)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Clientes'),
      ),
      body: StreamBuilder<List<ClienteBot>>(
        stream: _streamClientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aún no tienes clientes registrados.'));
          }

          final clientes = snapshot.data!;
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(cliente.plataforma == 'telegram' ? Icons.telegram : Icons.person),
                  ),
                  title: Text(cliente.nombre),
                  subtitle: Text(cliente.telefono ?? 'Sin teléfono'),
                  trailing: Icon(Icons.edit),
                  onTap: () {
                    // Navegar a edición
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaginaEditarCliente(cliente: cliente),
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
          // Navegar a creación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaEditarCliente(cliente: null),
            ),
          );
        },
      ),
    );
  }
}