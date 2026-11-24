import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Capsula del marcador: arriba el texto (PUNTOS, MEJOR...) y abajo el numero.
/// Fondo con el degradado de marca (violeta -> cian).
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
    const texto = AppColores.textoSobreMarca;
    // GestureDetector para poder detectar el doble toque
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        // ancho minimo para que todas las capsulas midan parecido aunque el numero sea corto
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacios.l,
          vertical: AppEspacios.s + AppEspacios.xs,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColores.degradadoMarca,
          ),
          borderRadius: BorderRadius.circular(AppTamanos.radioTarjeta),
          boxShadow: [
            BoxShadow(
              color: AppColores.degradadoMarca.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // que ocupe solo lo que necesita
          children: [
            Text(
              etiqueta.toUpperCase(),
              style: AppTextos.etiquetaMarcador(context)
                  .copyWith(color: texto.withValues(alpha: 0.85)),
            ),
            Text(
              '$valor',
              style: AppTextos.valorMarcador(context).copyWith(color: texto),
            ),
          ],
        ),
      ),
    );
  }
}
