// lib/pagina_mis_horarios.dart
import 'package:flutter/material.dart';

class PaginaMisHorarios extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Horarios'),
      ),
      body: Center(
        child: Text('Aquí podrás definir tus horas de trabajo para el bot.'),
        // Próximamente: Una lista de los 7 días de la semana
        // para añadir/editar los horarios de la tabla 'horarios_disponibles'
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Próximamente: Abrir formulario para añadir nuevo horario
        },
      ),
    );
  }
}