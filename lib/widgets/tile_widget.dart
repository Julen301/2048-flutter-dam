import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Una ficha del tablero. Si valor es 0 se pinta como celda vacia.
/// Tambien se usa en las listas, en detalle y en ajustes (vista previa).
///
/// Tiene dos animaciones:
///  - AnimatedContainer: cuando cambia el valor el color cambia poco a poco.
///  - TweenAnimationBuilder: si la ficha es nueva crece de 0 a 1, y si viene
///    de una fusion empieza un poco mas grande (1.2) y vuelve a su tamaño.
class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.valor,
    required this.lado,
    this.esNueva = false,
    this.esFusion = false,
  });

  final int valor;
  final double lado; // ancho y alto de la ficha (es cuadrada)
  final bool esNueva;
  final bool esFusion;

  @override
  Widget build(BuildContext context) {
    final fichas = FichasTheme.of(context);

    // Semantics es para el lector de pantalla (accesibilidad)
    final ficha = Semantics(
      label: valor == 0 ? 'Celda vacía' : 'Ficha $valor',
      child: AnimatedContainer(
        duration: AppDuraciones.ficha,
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fichas.colorFicha(valor),
          borderRadius: BorderRadius.circular(AppTamanos.radioFicha),
        ),
        // la celda vacia no lleva texto
        child: valor == 0
            ? null
            : Text(
                '$valor',
                style: AppTextos.ficha(lado, valor, fichas.colorTexto(valor)),
              ),
      ),
    );

    // si no es nueva ni fusion no hace falta animar la escala
    if (!esNueva && !esFusion) return ficha;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: esNueva ? 0.0 : 1.2, end: 1.0),
      duration: AppDuraciones.aparicion,
      // easeOutBack se pasa un poco de 1 y vuelve, da efecto de rebote
      curve: esNueva ? Curves.easeOutBack : Curves.easeOut,
      builder: (context, escala, child) =>
          Transform.scale(scale: escala, child: child),
      child: ficha, // se pasa como child para no reconstruirla en cada frame
    );
  }
}
