import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta para enseñar un dato: icono a la izquierda y titulo + valor.
/// La usamos en ranking (estadisticas) y en el detalle de una partida.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor; // es String para poder pasar tambien fechas o "01:15"
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero, // el espacio entre tarjetas ya lo pone el GridView
      child: Padding(
        padding: const EdgeInsets.all(AppEspacios.m),
        child: Row(
          children: [
            Icon(icono, color: tema.colorScheme.primary),
            const SizedBox(width: AppEspacios.m),
            // Expanded para que el texto use el resto del ancho
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: tema.textTheme.labelMedium),
                  Text(
                    valor,
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    // si no cabe pone "..." en vez de dar overflow
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
