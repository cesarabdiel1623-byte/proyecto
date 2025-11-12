// lib/pagina_citas.dart
import 'package:flutter/material.dart';

class PaginaCitas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Citas'),
        // Quitamos el botón de logout de aquí
      ),
      body: Center(
        child: Text('Aquí se mostrarán tus citas pendientes y pasadas.'),
        // Más adelante, aquí pondremos un FutureBuilder 
        // para consultar la tabla 'citas'
      ),
    );
  }
}