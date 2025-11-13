
// lib/pagina_detalle_empleado.dart
import 'package:flutter/material.dart';
import 'pagina_mis_empleados.dart'; // Para la clase Empleado

class PaginaDetalleEmpleado extends StatelessWidget {
  final Empleado empleado;

  const PaginaDetalleEmpleado({Key? key, required this.empleado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(empleado.nombre),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Especialidad: ${empleado.especialidad}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Sucursal: ${empleado.sucursalNombre}', style: TextStyle(fontSize: 18)),
            // Aquí puedes añadir más detalles o botones de acción
          ],
        ),
      ),
    );
  }
}
