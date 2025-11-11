// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'paginas_auth.dart'; // Importamos nuestro nuevo archivo
import 'pagina_home.dart'; // Importamos la página Home

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // 1. Pega tu URL aquí
    url: 'https://giibrukztrwsxxtxfqrj.supabase.co',

    // 2. Pega tu llave 'anon' aquí
    anonKey:
        'sb_publishable_IrsFjRQZB8wcTvVhLqKyjQ_fpNFrd64',
  );

  runApp(MyApp());
}

// Guarda el cliente en una variable global
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peluquería',
      theme: ThemeData(primarySwatch: Colors.blue),
      // AuthGate maneja a dónde ir:
      home: AuthGate(),
    );
  }
}

// Este Widget es el "Guardia de Autenticación" (AuthGate)
// Decide si mostrar la página de Login o la Home
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha los cambios de autenticación
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Si hay una sesión de usuario activa...
        if (snapshot.hasData && snapshot.data?.session != null) {
          // ...llévalo a la página Home
          return PaginaHome();
        }

        // Si no hay sesión...
        // ...llévalo a la página de Login (que es tu requisito inicial)
        return PaginaLogin();
      },
    );
  }
}
