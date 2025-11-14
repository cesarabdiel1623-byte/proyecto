// lib/pagina_editar_horario.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Para supabase

class PaginaEditarHorario extends StatefulWidget {
  final int empleadoId; // Recibe el ID del empleado
  PaginaEditarHorario({required this.empleadoId});

  @override
  _PaginaEditarHorarioState createState() => _PaginaEditarHorarioState();
}

class _PaginaEditarHorarioState extends State<PaginaEditarHorario> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int? _diaSeleccionado;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;

  // Lista de días de la semana
  final Map<int, String> _diasSemana = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles', 
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    0: 'Domingo',
  };
  
  // Función para mostrar el selector de hora
  Future<TimeOfDay?> _seleccionarHora(BuildContext context, TimeOfDay? horaInicial) async {
    return await showTimePicker(
      context: context,
      initialTime: horaInicial ?? TimeOfDay(hour: 9, minute: 0),
    );
  }

  Future<void> _guardarHorario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, selecciona una hora de inicio y fin.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    // Formateamos la hora para Supabase (ej: "09:00:00")
    final horaInicioStr = '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}:00';
    final horaFinStr = '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}:00';

    setState(() => _isLoading = true);

    try {
      final datos = {
        'empleado_id': widget.empleadoId,
        'dia_semana': _diaSeleccionado,
        'hora_inicio': horaInicioStr,
        'hora_fin': horaFinStr,
        'es_descanso': false,
      };

      await supabase.from('horarios_disponibles').insert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Horario guardado!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Regresa a la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Horario'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            // Dropdown para DÍA DE LA SEMANA
            DropdownButtonFormField<int>(
              value: _diaSeleccionado,
              decoration: InputDecoration(labelText: 'Día de la semana'),
              hint: Text('Selecciona un día'),
              items: _diasSemana.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _diaSeleccionado = value);
              },
              validator: (val) => val == null ? 'El día es obligatorio' : null,
            ),
            SizedBox(height: 12),

            // Selector de HORA INICIO
            ListTile(
              title: Text('Hora de Inicio'),
              subtitle: Text(_horaInicio?.format(context) ?? 'No seleccionada'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final hora = await _seleccionarHora(context, _horaInicio);
                if (hora != null) {
                  setState(() => _horaInicio = hora);
                }
              },
            ),
            
            // Selector de HORA FIN
            ListTile(
              title: Text('Hora de Fin'),
              subtitle: Text(_horaFin?.format(context) ?? 'No seleccionada'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final hora = await _seleccionarHora(context, _horaFin);
                if (hora != null) {
                  setState(() => _horaFin = hora);
                }
              },
            ),

            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _guardarHorario,
                    child: Text('Guardar Horario'),
                  ),
          ],
        ),
      ),
    );
  }
}