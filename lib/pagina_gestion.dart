// lib/pagina_gestion.dart
import 'package:flutter/material.dart';
import 'pagina_mis_servicios.dart';
import 'pagina_mis_empleados.dart'; 
import 'pagina_mis_sucursales.dart';
import 'pagina_mis_clientes.dart'; // <-- 1. Importamos la nueva página

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
          // Botón Mis Servicios
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

          // Botón Mis Empleados
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Mis Empleados'),
            subtitle: Text('Gestiona los empleados y sus horarios'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisEmpleados()),
              );
            },
          ),
          Divider(),

          // Botón Mis Sucursales
          ListTile(
            leading: Icon(Icons.store),
            title: Text('Mis Sucursales'),
            subtitle: Text('Añade o edita tus locales'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisSucursales()),
              );
            },
          ),
          Divider(),

          // --- 2. AQUÍ ESTÁ EL NUEVO BOTÓN "MIS CLIENTES" ---
          ListTile(
            leading: Icon(Icons.contact_phone),
            title: Text('Mis Clientes'),
            subtitle: Text('Gestiona tu lista de clientes'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaginaMisClientes()),
              );
            },
          ),

        ],
      ),
    );
  }
}