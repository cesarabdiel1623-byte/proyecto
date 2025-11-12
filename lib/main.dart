// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'paginas_auth.dart';
// 1. IMPORTA TU NUEVO HOME
import 'home_principal.dart'; 

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

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peluquería',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
    );
  }
}

// EL ÚNICO CAMBIO ESTÁ AQUÍ
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        
        if (snapshot.hasData && snapshot.data?.session != null) {
          // 2. CAMBIA ESTA LÍNEA
          return HomePrincipal(); // Antes decía PaginaHome()
        }

        return PaginaLogin(); 
      },
    );
  }
}