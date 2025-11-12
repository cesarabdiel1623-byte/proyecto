// lib/home_principal.dart
import 'package:flutter/material.dart';
// ¡Importamos las nuevas páginas que vamos a crear!
import 'pagina_calendario.dart';
import 'pagina_gestion.dart';
import 'pagina_perfil.dart'; // Esta ya la tenías

class HomePrincipal extends StatefulWidget {
  @override
  _HomePrincipalState createState() => _HomePrincipalState();
}

class _HomePrincipalState extends State<HomePrincipal> {
  int _paginaActual = 0; 

  // ACTUALIZAMOS LA LISTA DE PÁGINAS
  final List<Widget> _paginas = [
    PaginaCalendario(), // La nueva página principal
    PaginaGestion(),    // La nueva página de ajustes
    PaginaPerfil(),     // La página de perfil que ya teníamos
  ];

  void _onTabTapped(int index) {
    setState(() {
      _paginaActual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_paginaActual],

      // ACTUALIZAMOS LAS PESTAÑAS
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario', // Antes: Sucursales
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Gestión', // Antes: Mis Citas
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil', // Esta se queda igual
          ),
        ],
      ),
    );
  }
}