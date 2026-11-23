import 'package:flutter/material.dart';

import '../game/juego_2048.dart';
import '../theme/app_theme.dart';

/// Botones de dirección: alternativa accesible al swipe.
class ControlesDireccion extends StatelessWidget {
  const ControlesDireccion({super.key, required this.onMover});

  final ValueChanged<Direccion> onMover;

  @override
  Widget build(BuildContext context) {
    Widget boton(Direccion d, IconData icono, String texto) => IconButton.filledTonal(
          tooltip: texto,
          onPressed: () => onMover(d),
          icon: Icon(icono),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppEspacios.s,
      children: [
        boton(Direccion.izquierda, Icons.keyboard_arrow_left, 'Izquierda'),
        boton(Direccion.arriba, Icons.keyboard_arrow_up, 'Arriba'),
        boton(Direccion.abajo, Icons.keyboard_arrow_down, 'Abajo'),
        boton(Direccion.derecha, Icons.keyboard_arrow_right, 'Derecha'),
      ],
    );
  }
}
