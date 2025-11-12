// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'paginas_auth.dart'; 
import 'home_principal.dart'; 

// --- 1. IMPORTA ESTOS DOS PAQUETES ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart'; // Para las fechas

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- 2. INICIALIZA LOS FORMATOS DE FECHA EN ESPAÑOL ---
  await initializeDateFormatting('es_ES', null);

  await Supabase.initialize(
    url: 'https://TU_PROYECTO_ID.supabase.co',
    anonKey: 'TU_CLAVE_ANON',
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
        primarySwatch: Colors.purple, // Vamos a darle un color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // --- 3. AÑADE ESTAS LÍNEAS PARA LA LOCALIZACIÓN ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', 'ES'), // Español
        // ... puedes añadir 'en', 'US' si quieres dar soporte a inglés
      ],
      // --- FIN DE LAS LÍNEAS NUEVAS ---

      home: AuthGate(),
    );
  }
}

// (El código de AuthGate se queda exactamente igual)
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