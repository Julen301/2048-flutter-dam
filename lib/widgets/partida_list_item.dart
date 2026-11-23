import 'package:flutter/material.dart';

import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'tile_widget.dart';

/// Una fila de la lista de partidas. Sirve para el historial y para el ranking.
class PartidaListItem extends StatelessWidget {
  const PartidaListItem({
    super.key,
    required this.partida,
    this.posicion,
    this.onTap,
    this.onLongPress,
  });

  final Partida partida;

  /// Puesto en el ranking (del 1 al 10).
  /// En el historial se deja a null y asi sabemos como pintar la fila.
  final int? posicion;
  final VoidCallback? onTap; // abrir el detalle
  final VoidCallback? onLongPress; // menu de opciones (solo en historial)

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // ficha pequeña con la ficha maxima que se consiguio en la partida
    final miniatura = TileWidget(
      valor: partida.fichaMaxima,
      lado: AppTamanos.fichaMiniatura,
    );

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        // historial: ficha a la izquierda
        // ranking: circulo con la posicion (#1, #2...) a la izquierda
        leading: posicion == null
            ? miniatura
            : CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                child: Text(
                  '#$posicion',
                  style: TextStyle(color: tema.colorScheme.onPrimaryContainer),
                ),
              ),
        title: Text(
          // si la partida no trae el nombre del usuario ponemos "Jugador"
          '${partida.puntuacion} pts · ${partida.usuario ?? 'Jugador'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${formatearFecha(partida.fecha)} · '
          '${partida.movimientos} mov. · '
          '${formatearDuracion(partida.duracionSegundos)}',
        ),
        // en el historial una flecha, en el ranking la ficha a la derecha
        trailing: posicion == null ? const Icon(Icons.chevron_right) : miniatura,
      ),
    );
  }
}
