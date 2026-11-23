import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cajita del marcador: arriba el texto (PUNTOS, MEJOR...) y abajo el numero.
/// Se usa en la pantalla de juego y en inicio.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.onDoubleTap,
  });

  final String etiqueta;
  final int valor;

  /// Es opcional. En el juego, con doble toque en PUNTOS se enseñan u
  /// ocultan los detalles de la partida. Si es null el doble toque no hace nada.
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    // GestureDetector para poder detectar el doble toque
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        // ancho minimo para que todas las cajas midan parecido aunque el numero sea corto
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacios.m,
          vertical: AppEspacios.s,
        ),
        decoration: BoxDecoration(
          color: esquema.primaryContainer,
          borderRadius: BorderRadius.circular(AppTamanos.radioFicha),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // que ocupe solo lo que necesita
          children: [
            Text(
              etiqueta.toUpperCase(),
              style: AppTextos.etiquetaMarcador(context)
                  .copyWith(color: esquema.onPrimaryContainer),
            ),
            Text(
              '$valor',
              style: AppTextos.valorMarcador(context)
                  .copyWith(color: esquema.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
