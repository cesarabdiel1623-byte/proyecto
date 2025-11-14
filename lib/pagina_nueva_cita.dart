// lib/pagina_nueva_cita.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'main.dart'; // Para supabase
import 'pagina_mis_servicios.dart'; // Para la clase Servicio
import 'pagina_mis_empleados.dart'; // Para la clase Empleado
import 'pagina_mis_clientes.dart';  // Para la clase ClienteBot

// Clase para los datos de los 3 dropdowns
class DatosFormularioCita {
  final List<Servicio> servicios;
  final List<Empleado> empleados;
  final List<ClienteBot> clientes;
  DatosFormularioCita({required this.servicios, required this.empleados, required this.clientes});
}

class PaginaNuevaCita extends StatefulWidget {
  final DateTime diaSeleccionado;
  PaginaNuevaCita({required this.diaSeleccionado});

  @override
  _PaginaNuevaCitaState createState() => _PaginaNuevaCitaState();
}

class _PaginaNuevaCitaState extends State<PaginaNuevaCita> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Future para cargar los datos de los 3 dropdowns
  late final Future<DatosFormularioCita> _futureDatosFormulario;
  
  // Variables para guardar la selección
  int? _servicioSeleccionadoId;
  int? _empleadoSeleccionadoId;
  int? _clienteSeleccionadoId;
  TimeOfDay? _horaInicioSeleccionada;
  Servicio? _servicioSeleccionado; // Para saber la duración

  @override
  void initState() {
    super.initState();
    _futureDatosFormulario = _cargarDatosFormulario();
  }

  // Carga los datos de las 3 tablas en paralelo
  Future<DatosFormularioCita> _cargarDatosFormulario() async {
    try {
      final negocioId = (await supabase
          .from('usuarios_perfiles')
          .select('negocio_id')
          .eq('id', supabase.auth.currentUser!.id)
          .single())['negocio_id'] as String;

      // Creamos 3 "tareas"
      final taskServicios = supabase.from('servicios').select().eq('negocio_id', negocioId);
      final taskEmpleados = supabase.from('empleados').select('*, sucursales(nombre)').eq('negocio_id', negocioId);
      final taskClientes = supabase.from('clientes_bot').select().eq('negocio_id', negocioId);

      // Las ejecutamos al mismo tiempo
      final [dataServicios, dataEmpleados, dataClientes] = 
          await Future.wait([taskServicios, taskEmpleados, taskClientes]);

      // Convertimos los resultados a nuestras clases
      return DatosFormularioCita(
        servicios: dataServicios.map((map) => Servicio.fromMap(map)).toList(),
        empleados: dataEmpleados.map((map) => Empleado.fromMap(map)).toList(),
        clientes: dataClientes.map((map) => ClienteBot.fromMap(map)).toList(),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fatal al cargar datos: $e'),
          backgroundColor: Colors.red,
        ));
      }
      throw Exception('No se pudieron cargar los datos del formulario');
    }
  }
  
  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (hora != null) {
      setState(() => _horaInicioSeleccionada = hora);
    }
  }
  
  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate()) return;
    if (_servicioSeleccionado == null || _empleadoSeleccionadoId == null || _clienteSeleccionadoId == null || _horaInicioSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Por favor, completa todos los campos.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // 1. Obtener datos del negocio y sucursal
      final negocioId = (await supabase
          .from('usuarios_perfiles')
          .select('negocio_id')
          .eq('id', supabase.auth.currentUser!.id)
          .single())['negocio_id'];
      
      final sucursalId = (await supabase
          .from('empleados')
          .select('sucursal_id')
          .eq('id', _empleadoSeleccionadoId!)
          .single())['sucursal_id'];

      // 2. Calcular fechas y horas
      final fecha = widget.diaSeleccionado;
      final hora = _horaInicioSeleccionada!;
      final fechaHoraInicio = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
      final fechaHoraFin = fechaHoraInicio.add(Duration(minutes: _servicioSeleccionado!.duracion));

      // 3. Preparar los datos
      final datos = {
        'negocio_id': negocioId,
        'sucursal_id': sucursalId,
        'empleado_id': _empleadoSeleccionadoId,
        'servicio_id': _servicioSeleccionadoId,
        'cliente_id': _clienteSeleccionadoId,
        'fecha_hora_inicio': fechaHoraInicio.toIso8601String(),
        'fecha_hora_fin': fechaHoraFin.toIso8601String(),
        'estado': 'confirmada', // Las citas manuales se confirman al instante
        'creada_por': 'manual', // Creada por el barbero
      };
      
      // 4. Insertar en la tabla 'citas'
      await supabase.from('citas').insert(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('¡Cita agendada!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context); // Regresa al calendario
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar la cita: $e'),
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
        title: Text('Agendar Nueva Cita'),
      ),
      body: FutureBuilder<DatosFormularioCita>(
        future: _futureDatosFormulario,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No se pudieron cargar los datos.'));
          }

          // ¡Tenemos los datos para los dropdowns!
          final datosForm = snapshot.data!;

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                // --- Selector de Cliente ---
                DropdownButtonFormField<int>(
                  value: _clienteSeleccionadoId,
                  decoration: InputDecoration(labelText: 'Cliente'),
                  hint: Text('Selecciona un cliente'),
                  items: datosForm.clientes.map((cliente) {
                    return DropdownMenuItem(
                      value: cliente.id,
                      child: Text(cliente.nombre),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _clienteSeleccionadoId = value),
                  validator: (val) => val == null ? 'Selecciona un cliente' : null,
                ),
                SizedBox(height: 12),

                // --- Selector de Servicio ---
                DropdownButtonFormField<int>(
                  value: _servicioSeleccionadoId,
                  decoration: InputDecoration(labelText: 'Servicio'),
                  hint: Text('Selecciona un servicio'),
                  items: datosForm.servicios.map((servicio) {
                    return DropdownMenuItem(
                      value: servicio.id,
                      child: Text(servicio.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _servicioSeleccionadoId = value;
                      // Guardamos el objeto 'servicio' para saber su duración
                      _servicioSeleccionado = datosForm.servicios.firstWhere((s) => s.id == value);
                    });
                  },
                  validator: (val) => val == null ? 'Selecciona un servicio' : null,
                ),
                SizedBox(height: 12),

                // --- Selector de Empleado ---
                DropdownButtonFormField<int>(
                  value: _empleadoSeleccionadoId,
                  decoration: InputDecoration(labelText: 'Empleado'),
                  hint: Text('Selecciona un empleado'),
                  items: datosForm.empleados.map((empleado) {
                    return DropdownMenuItem(
                      value: empleado.id,
                      child: Text(empleado.nombre),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _empleadoSeleccionadoId = value),
                  validator: (val) => val == null ? 'Selecciona un empleado' : null,
                ),
                SizedBox(height: 12),

                // --- Selector de Fecha (viene de la pág. anterior) ---
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Fecha'),
                  subtitle: Text(DateFormat.yMMMMd('es_ES').format(widget.diaSeleccionado)),
                ),

                // --- Selector de Hora ---
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('Hora de Inicio'),
                  subtitle: Text(_horaInicioSeleccionada?.format(context) ?? 'No seleccionada'),
                  onTap: _seleccionarHora,
                ),

                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _guardarCita,
                        child: Text('Guardar Cita'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}