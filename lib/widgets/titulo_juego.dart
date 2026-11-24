import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// El titulo "2048" con el degradado de marca y una frase debajo.
/// Se usa en inicio y en login para que las dos pantallas tengan la misma
/// cabecera.
class TituloJuego extends StatelessWidget {
  const TituloJuego({super.key, this.lema = 'DESLIZA · FUSIONA · BRILLA'});

  /// Frase pequeña de debajo. Si es null no se pinta.
  final String? lema;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ShaderMask pinta el texto con el degradado en vez de un color liso
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => const LinearGradient(
            colors: AppColores.degradadoMarca,
          ).createShader(rect),
          child: Text(
            '2048',
            textAlign: TextAlign.center,
            style: AppTextos.tituloJuego(context),
          ),
        ),
        if (lema != null) ...[
          const SizedBox(height: AppEspacios.s),
          Text(lema!, textAlign: TextAlign.center, style: AppTextos.lemaJuego(context)),
        ],
      ],
    );
  }
}
