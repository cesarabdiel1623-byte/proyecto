// lib/pagina_calendario.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import 'main.dart'; 
import 'pagina_nueva_cita.dart';

// Clase CitaCompleta (sin cambios)
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
      // --- ¡CAMBIO SUTIL AQUÍ! ---
      // Leemos los datos de la relación que especificamos
      nombreServicio: map['servicios']['nombre'] ?? 'Servicio no encontrado',
      // 'citas_cliente_id_fkey' es el nombre de la relación original
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
  CalendarFormat _calendarFormat = CalendarFormat.week;
  Stream<List<CitaCompleta>>? _citasStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    _citasStream = supabase
        .from('citas')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
          final endOfDay = startOfDay.add(Duration(days: 1));

          // --- ¡¡AQUÍ ESTÁ LA CORRECCIÓN!! ---
          // Le decimos a Supabase EXACTAMENTE qué relación usar para 'clientes_bot'
          final citasData = await supabase
              .from('citas')
              .select(
                  '*, servicios(nombre), empleados(nombre), clientes_bot!citas_cliente_id_fkey(nombre)')
              .gte('fecha_hora_inicio', startOfDay.toIso8601String())
              .lt('fecha_hora_inicio', endOfDay.toIso8601String())
              .order('fecha_hora_inicio', ascending: true); 

          return citasData.map((map) => CitaCompleta.fromMap(map)).toList();
        });
  }

  // _onDaySelected (sin cambios)
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
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
          TableCalendar(
            // Bloqueamos fechas anteriores como pediste
            firstDay: DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day), 
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'es_ES',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          Divider(thickness: 1),
          Expanded(
            child: StreamBuilder<List<CitaCompleta>>(
              stream: _citasStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar citas: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay citas para\n${DateFormat.yMMMMd('es_ES').format(_selectedDay)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }
                final citas = snapshot.data!;
                return ListView.builder(
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final cita = citas[index];
                    final horaInicio = DateFormat.jm().format(cita.fechaHoraInicio);
                    final horaFin = DateFormat.jm().format(cita.fechaHoraFin);
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.cut)),
                        title: Text(cita.nombreServicio),
                        subtitle: Text('${cita.nombreCliente}\ncon ${cita.nombreEmpleado}'),
                        trailing: Text(
                          '$horaInicio - $horaFin',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaNuevaCita(
                // Le pasamos el día seleccionado en el calendario
                diaSeleccionado: _selectedDay, 
              ),
            ),
          );
        },
      ),
    );
  }
}