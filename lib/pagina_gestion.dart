// lib/pagina_gestion.dart
import 'package:flutter/material.dart';
import 'pagina_mis_servicios.dart';
import 'pagina_mis_horarios.dart'; // Importamos el nuevo archivo
import 'pagina_mis_empleados.dart'; // Importamos el nuevo archivo

class PaginaGestion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar mi Negocio'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Botón Mis Servicios (Este ya lo teníamos)
          ListTile(
            leading: Icon(Icons.content_cut),
            title: Text('Mis Servicios'),
            subtitle: Text('Edita tus precios, nombres y duraciones'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisServicios()),
              );
            },
          ),
          Divider(),
          
          // --- CONEXIÓN DE "MIS HORARIOS" ---
          ListTile(
            leading: Icon(Icons.access_time_filled),
            title: Text('Mis Horarios'),
            subtitle: Text('Define tus horas de trabajo para el bot'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisHorarios()),
              );
            },
          ),
          Divider(),
          
          // --- CONEXIÓN DE "MIS EMPLEADOS" ---
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Mis Empleados'),
            subtitle: Text('Gestiona los empleados de tu sucursal'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisEmpleados()),
              );
            },
          ),
        ],
      ),
    );
  }
}