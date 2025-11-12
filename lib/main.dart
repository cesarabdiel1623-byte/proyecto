// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'paginas_auth.dart';
import 'home_principal.dart';

// Importa los paquetes de localización
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para las fechas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los formatos de fecha en español
  await initializeDateFormatting('es_ES', null);

  await Supabase.initialize(
    // 1. Esta URL es la correcta (la de tu proyecto Kyros)
    url: 'https://giibrukztrwsxxtxfqrj.supabase.co',

    // 2. ¡¡ERROR CORREGIDO!!
    // Pega aquí tu llave 'anon' (la que empieza con 'eyJ...')
    // ¡NO uses la llave 'sb_publishable_...'!
    anonKey: 'sb_publishable_IrsFjRQZB8wcTvVhLqKyjQ_fpNFrd64',
  );

  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyros Barber',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // Añade las líneas de localización para el calendario
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', 'ES'), // Español
      ],

      home: AuthGate(),
    );
  }
}

// AuthGate (se queda igual)
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          return HomePrincipal();
        }

        return PaginaLogin();
      },
    );
  }
}
