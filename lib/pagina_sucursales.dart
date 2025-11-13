
// lib/pagina_sucursales.dart
import 'package:flutter/material.dart';

class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final String negocioId;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.negocioId,
  });

  factory Sucursal.fromMap(Map<String, dynamic> map) {
    return Sucursal(
      id: map['id'],
      nombre: map['nombre'] ?? 'Sin nombre',
      direccion: map['direccion'] ?? 'Sin dirección',
      negocioId: map['negocio_id'],
    );
  }
}
