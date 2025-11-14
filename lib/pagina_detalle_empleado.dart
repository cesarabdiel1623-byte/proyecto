// lib/pagina_detalle_empleado.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase
import 'pagina_mis_empleados.dart'; // Para la clase Empleado
import 'pagina_editar_horario.dart'; // ¡El formulario que crearemos!

// --- Clase para el Horario ---
class Horario {
  final int id;
  final int diaSemana; // 0=Domingo, 1=Lunes, etc.
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  Horario({
    required this.id, 
    required this.diaSemana, 
    required this.horaInicio, 
    required this.horaFin
  });

  // Convertimos 'TIME' de Supabase (ej: "10:00:00") a TimeOfDay de Flutter
  static TimeOfDay _timeFromSupabase(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Helper para mostrar el nombre del día
  String get diaNombre {
    const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return dias[diaSemana];
  }

  factory Horario.fromMap(Map<String, dynamic> map) {
    return Horario(
      id: map['id'],
      diaSemana: map['dia_semana'],
      horaInicio: _timeFromSupabase(map['hora_inicio']),
      horaFin: _timeFromSupabase(map['hora_fin']),
    );
  }
}


class PaginaDetalleEmpleado extends StatefulWidget {
  final Empleado empleado;
  PaginaDetalleEmpleado({required this.empleado});

  @override
  _PaginaDetalleEmpleadoState createState() => _PaginaDetalleEmpleadoState();
}

class _PaginaDetalleEmpleadoState extends State<PaginaDetalleEmpleado> {
  // Un stream que escucha los horarios SÓLO de este empleado
  late final Stream<List<Horario>> _streamHorarios;

  @override
  void initState() {
    super.initState();
    _streamHorarios = supabase
        .from('horarios_disponibles')
        .stream(primaryKey: ['id'])
        // Filtramos por el 'empleado_id'
        .eq('empleado_id', widget.empleado.id)
        .order('dia_semana', ascending: true) // Ordenamos por día
        .map((data) => data.map((map) => Horario.fromMap(map)).toList());
  }

  Future<void> _borrarHorario(int horarioId) async {
    try {
      await supabase.from('horarios_disponibles').delete().eq('id', horarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Horario eliminado'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al borrar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.empleado.nombre),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                SizedBox(height: 12),
                Text(widget.empleado.nombre, style: Theme.of(context).textTheme.headlineSmall),
                Text(widget.empleado.especialidad, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          
          Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Horarios de Trabajo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          // --- Aquí mostramos la lista de horarios ---
          StreamBuilder<List<Horario>>(
            stream: _streamHorarios,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(child: Text('Este empleado aún no tiene horarios definidos.')),
                );
              }
              
              final horarios = snapshot.data!;
              return Column(
                children: horarios.map((horario) {
                  return ListTile(
                    title: Text(horario.diaNombre),
                    subtitle: Text('${horario.horaInicio.format(context)} - ${horario.horaFin.format(context)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _borrarHorario(horario.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      // --- El botón '+' para AÑADIR HORARIO ---
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Abre el formulario, pasándole el ID del empleado
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaEditarHorario(empleadoId: widget.empleado.id),
            ),
          );
        },
      ),
    );
  }
}