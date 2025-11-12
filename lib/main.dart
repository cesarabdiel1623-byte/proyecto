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
    url: 'https://mlbsfssnnbjpprmxchzo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sYnNmc3NubmJqcHBybXhjaHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU2MzM5NDAsImV4cCI6MjAzMTIwOTk0MH0.G21303-e3Bf_2aA-wT242-1i43p_3-enB4f_4b-e3Bf',
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