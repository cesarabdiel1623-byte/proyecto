// lib/home_principal.dart
import 'package:flutter/material.dart';
import 'pagina_sucursales.dart'; // La página que ya tenías
import 'pagina_citas.dart';       // La nueva página de citas
import 'pagina_perfil.dart';      // La nueva página de perfil

class HomePrincipal extends StatefulWidget {
  @override
  _HomePrincipalState createState() => _HomePrincipalState();
}

class _HomePrincipalState extends State<HomePrincipal> {
  // Índice para saber qué pestaña está seleccionada
  int _paginaActual = 0; 

  // La lista de las 3 páginas que creamos
  final List<Widget> _paginas = [
    PaginaSucursales(),
    PaginaCitas(),
    PaginaPerfil(),
  ];

  // Función que se llama cuando se toca una pestaña
  void _onTabTapped(int index) {
    setState(() {
      _paginaActual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El cuerpo de la app será la página que esté seleccionada
      body: _paginas[_paginaActual],

      // --- Aquí están las pestañas ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual, // Marca el ícono seleccionado
        onTap: _onTabTapped,       // Llama a nuestra función al tocar
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.store_mall_directory),
            label: 'Sucursales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Mis Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}