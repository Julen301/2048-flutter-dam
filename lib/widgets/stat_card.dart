import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta para enseñar un dato: icono en un cuadrado de color a la
/// izquierda y titulo + valor.
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
    final esquema = tema.colorScheme;
    return Card(
      margin: EdgeInsets.zero, // el espacio entre tarjetas ya lo pone el GridView
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspacios.m,
          vertical: AppEspacios.s + AppEspacios.xs,
        ),
        child: Row(
          children: [
            // icono dentro de un cuadrado redondeado con el color primario suave
            Container(
              padding: const EdgeInsets.all(AppEspacios.s),
              decoration: BoxDecoration(
                color: esquema.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTamanos.radioFicha),
              ),
              child: Icon(icono, color: esquema.primary),
            ),
            const SizedBox(width: AppEspacios.m),
            // Expanded para que el texto use el resto del ancho
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titulo.toUpperCase(),
                    style: tema.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    valor,
                    style: tema.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
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
