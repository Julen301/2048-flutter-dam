import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Una ficha del tablero. Si valor es 0 se pinta como celda vacia.
/// Tambien se usa en las listas, en detalle y en ajustes (vista previa).
///
/// Estilo "Neón": cada ficha lleva un degradado (mas claro arriba a la
/// izquierda) y, a partir del 8, un halo de luz de su propio color que
/// crece con el valor.
///
/// Tiene dos animaciones:
///  - AnimatedContainer: cuando cambia el valor el color y el brillo cambian poco a poco.
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

  // Radio proporcional al lado: en las miniaturas no queda un circulo
  double get _radio => (lado * 0.22).clamp(6.0, AppTamanos.radioFicha);

  @override
  Widget build(BuildContext context) {
    final fichas = FichasTheme.of(context);
    final color = fichas.colorFicha(valor);

    // Semantics es para el lector de pantalla (accesibilidad)
    final ficha = Semantics(
      label: valor == 0 ? 'Celda vacía' : 'Ficha $valor',
      child: AnimatedContainer(
        duration: AppDuraciones.ficha,
        width: lado,
        height: lado,
        alignment: Alignment.center,
        decoration: valor == 0
            ? _decoracionVacia(color, fichas.textoClaro)
            : _decoracionFicha(color),
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

  // celda vacia: color liso con un borde interior muy suave
  BoxDecoration _decoracionVacia(Color color, Color brillo) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_radio),
        border: Border.all(color: brillo.withValues(alpha: 0.05)),
      );

  BoxDecoration _decoracionFicha(Color color) {
    // color un poco mas claro para la esquina de arriba del degradado
    final hsl = HSLColor.fromColor(color);
    final claro = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();

    // el halo empieza en el 8 y va creciendo: 8 -> 1, 16 -> 2 ... 2048 -> 9
    var nivel = 0;
    for (var v = valor; v > 4; v >>= 1) {
      nivel++;
    }
    final halo = nivel == 0
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: color.withValues(alpha: 0.35 + nivel * 0.03),
              blurRadius: lado * (0.10 + nivel * 0.025),
              spreadRadius: nivel >= 8 ? 1 : 0,
            ),
          ];

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [claro, color],
      ),
      borderRadius: BorderRadius.circular(_radio),
      boxShadow: halo,
    );
  }
}
