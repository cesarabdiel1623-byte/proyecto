// lib/pagina_calendario.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'main.dart'; // Para supabase

// --- Creamos una clase para la Cita ---
// (Es más compleja porque trae datos de otras tablas)
class CitaCompleta {
  final int id;
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final String nombreServicio;
  final String nombreCliente;
  final String nombreEmpleado;

  CitaCompleta({
    required this.id,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.nombreServicio,
    required this.nombreCliente,
    required this.nombreEmpleado,
  });

  factory CitaCompleta.fromMap(Map<String, dynamic> map) {
    return CitaCompleta(
      id: map['id'],
      fechaHoraInicio: DateTime.parse(map['fecha_hora_inicio']),
      fechaHoraFin: DateTime.parse(map['fecha_hora_fin']),
      // Leemos los datos de las tablas "unidas"
      nombreServicio: map['servicios']['nombre'] ?? 'Servicio no encontrado',
      nombreCliente: map['clientes_bot']['nombre'] ?? 'Cliente (Bot)',
      nombreEmpleado: map['empleados']['nombre'] ?? 'Empleado no encontrado',
    );
  }
}

class PaginaCalendario extends StatefulWidget {
  @override
  _PaginaCalendarioState createState() => _PaginaCalendarioState();
}

class _PaginaCalendarioState extends State<PaginaCalendario> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat =
      CalendarFormat.week; // Empezamos con vista semanal

  // El Stream que escuchará los cambios en la tabla 'citas'
  Stream<List<CitaCompleta>>? _citasStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    // Escuchamos la tabla 'citas' en tiempo real
    _citasStream = supabase
        .from('citas')
        // Escucha en tiempo real CUALQUIER cambio (INSERT, UPDATE, DELETE)
        .stream(primaryKey: ['id']).asyncMap((data) async {
      // Cuando hay un cambio, volvemos a pedir todas las citas
      // del día seleccionado, pero con los datos de las otras tablas

      // Calculamos el inicio y fin del día seleccionado
      final startOfDay =
          DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final citasData = await supabase
          .from('citas')
          // Pedimos datos de 'citas' y "unimos" los nombres de
          // las tablas servicios, clientes_bot y empleados
          .select(
              '*, servicios(nombre), clientes_bot(nombre), empleados(nombre)')
          // Filtramos por las citas del día seleccionado
          .gte('fecha_hora_inicio', startOfDay.toIso8601String())
          .lt('fecha_hora_inicio', endOfDay.toIso8601String())
          .order('fecha_hora_inicio', ascending: true); // Ordenamos por hora

      return citasData.map((map) => CitaCompleta.fromMap(map)).toList();
    });
  }

  // Función que se llama cuando se toca un día en el calendario
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Al cambiar de día, reiniciamos el stream para que
        // escuche los cambios del NUEVO día seleccionado
        _initializeStream();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Calendario'),
      ),
      body: Column(
        children: [
          // --- ESTE ES EL CALENDARIO INTERACTIVO ---
          TableCalendar(
            firstDay: DateTime.utc(
                DateTime.now().year, DateTime.now().month, DateTime.now().day),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'es_ES', // (Necesitarás configurar la localización)
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected, // ¡Aquí se hace clic!
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),

          Divider(thickness: 1),

          // --- ESTA ES LA LISTA DE CITAS EN TIEMPO REAL ---
          Expanded(
            child: StreamBuilder<List<CitaCompleta>>(
              stream: _citasStream,
              builder: (context, snapshot) {
                // Mientras carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                // Si hay un error
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error al cargar citas: ${snapshot.error}'));
                }
                // Si no hay datos (lista vacía)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay citas para\n${DateFormat.yMMMMd('es_ES').format(_selectedDay)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                // ¡Tenemos citas! Las mostramos
                final citas = snapshot.data!;
                return ListView.builder(
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final cita = citas[index];
                    // Formateamos la hora
                    final horaInicio =
                        DateFormat.jm().format(cita.fechaHoraInicio);
                    final horaFin = DateFormat.jm().format(cita.fechaHoraFin);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.cut)),
                        title: Text(cita.nombreServicio),
                        subtitle: Text(
                          '${cita.nombreCliente}\ncon ${cita.nombreEmpleado}',
                        ),
                        trailing: Text(
                          '$horaInicio - $horaFin',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Próximamente: Navegar a PaginaNuevaCitaManual()
          print('Agendar cita manualmente');
        },
      ),
    );
  }
}
