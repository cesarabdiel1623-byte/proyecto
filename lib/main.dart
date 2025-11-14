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
    // 1. Esta URL es la correcta
    url: 'https://giibrukztrwsxxtxfqrj.supabase.co',

    // 2. Esta es tu llave 'anon' que SÍ funciona
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
      
      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      theme: ThemeData(
        // 1. ESTA LÍNEA ACTIVA EL DISEÑO MODERNO (Material 3)
        // Y ARREGLARÁ TU CALENDARIO.
        useMaterial3: true, 
        
        // 2. Esta es la forma moderna de definir el color
        // (Reemplaza a 'primarySwatch')
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple), 
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // --- FIN DE LA CORRECCIÓN ---

      // Líneas de localización para el calendario
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