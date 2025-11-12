// lib/pagina_perfil.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para usar 'supabase'

// --- Creamos una clase para el perfil ---
class PerfilUsuario {
  final String nombre;
  final String? avatarUrl;

  PerfilUsuario({required this.nombre, this.avatarUrl});

  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    return PerfilUsuario(
      nombre: map['nombre'] ?? 'Sin nombre',
      avatarUrl: map['avatar_url'],
    );
  }
}

class PaginaPerfil extends StatefulWidget {
  @override
  _PaginaPerfilState createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  late final Future<PerfilUsuario?> _futurePerfil;

  @override
  void initState() {
    super.initState();
    _futurePerfil = _getPerfil();
  }

  // --- Función para buscar el perfil en la tabla 'usuarios_perfiles' ---
  Future<PerfilUsuario?> _getPerfil() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await supabase
          .from('usuarios_perfiles')
          .select('nombre, avatar_url') // Pedimos solo nombre y avatar
          .eq('id', user.id)           // Donde el id coincida
          .single(); // Esperamos un solo resultado

      return PerfilUsuario.fromMap(data);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar el perfil: $e'),
          backgroundColor: Colors.red,
        ));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
      ),
      // Usamos el FutureBuilder para esperar los datos
      body: FutureBuilder<PerfilUsuario?>(
        future: _futurePerfil,
        builder: (context, snapshot) {
          // --- MIENTRAS CARGA ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // --- SI HUBO UN ERROR O NO HAY PERFIL ---
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No se pudo cargar el perfil.'));
          }

          // --- ¡TENEMOS DATOS! ---
          final perfil = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- CÍRCULO CON LA FOTO DE PERFIL ---
              // --- CÍRCULO CON LA FOTO DE PERFIL ---
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200], // Color de fondo
            // 1. Quitamos 'backgroundImage'
            // 2. Ponemos la lógica en el 'child'
            child: (perfil.avatarUrl != null && perfil.avatarUrl!.isNotEmpty)
                ? ClipOval( // 3. Usamos ClipOval para que la imagen sea redonda
                    child: Image.network(
                      perfil.avatarUrl!,
                      fit: BoxFit.contain, // 4. Esta es la magia: "Contener"
                      width: 100,
                      height: 100,
                    ),
                  )
                : Icon(Icons.person, size: 50, color: Colors.grey[600]),
          ),
              SizedBox(height: 16),
              
              // --- MUESTRA EL NOMBRE ---
              Center(
                child: Text(
                  perfil.nombre, // Muestra el nombre de la BD
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),

              // Muestra el email (del sistema de Auth)
              Center(
                child: Text(
                  supabase.auth.currentUser!.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 32),
              
              // Botón de Cerrar Sesión
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                child: Text('Cerrar Sesión'),
              ),
            ],
          );
        },
      ),
    );
  }
}