// lib/paginas_auth.dart
import 'dart:io'; // Para manejar archivos (File)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para la foto
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para usar 'supabase'

// -----------------------------------------------------
// PÁGINA DE LOGIN (La que se muestra primero)
// -----------------------------------------------------
class PaginaLogin extends StatefulWidget {
  @override
  _PaginaLoginState createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Intenta iniciar sesión
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // NO necesitamos navegar. El StreamBuilder en main.dart
      // detectará el inicio de sesión y nos moverá a PaginaHome.
      
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de login: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Un error inesperado ocurrió: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _iniciarSesion,
                    child: Text('Iniciar Sesión'),
                  ),
            // Este es tu botón para registrarte
            TextButton(
              child: Text('¿No tienes cuenta? Regístrate'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PaginaRegistro()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// PÁGINA DE REGISTRO (con Foto de Perfil)
// -----------------------------------------------------
class PaginaRegistro extends StatefulWidget {
  @override
  _PaginaRegistroState createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _isLoading = false;
  File? _imagenPerfil; // Variable para guardar la imagen seleccionada

  // --- Función para seleccionar la imagen ---
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imagenPerfil = File(pickedFile.path);
      });
    }
  }

  Future<void> _registrarUsuario() async {
    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nombre = _nombreController.text.trim();
    final rol = 'cliente';
    String? urlImagenSubida;

    try {
      // 1. SUBIR LA FOTO PRIMERO (si existe)
      if (_imagenPerfil != null) {
        final bytes = await _imagenPerfil!.readAsBytes();
        final fileExt = _imagenPerfil!.path.split('.').last;
        final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
        
        await supabase.storage.from('avatars').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        
        urlImagenSubida = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

      // 2. CREAR EL USUARIO EN SUPABASE AUTH CON METADATOS
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
        data: {
          'nombre': nombre,
          'rol': rol,
          'avatar_url': urlImagenSubida,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Registro exitoso! Revisa tu correo para confirmar la cuenta.'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(); 
      }

    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de registro: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Un error inesperado ocurrió: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Cuenta Nueva')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // --- Widget para la foto de perfil ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imagenPerfil != null ? FileImage(_imagenPerfil!) : null,
                    child: _imagenPerfil == null ? Icon(Icons.person, size: 50) : null,
                  ),
                  TextButton(
                    onPressed: _seleccionarImagen,
                    child: Text('Seleccionar foto de perfil'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre Completo'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _registrarUsuario,
                    child: Text('Registrarme'),
                  ),
          ],
        ),
      ),
    );
  }
}