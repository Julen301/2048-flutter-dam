import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/stat_card.dart';
import '../widgets/tile_widget.dart';

/// Pantalla con todos los datos de una partida.
/// Solo recibe el id y la busca en la base de datos, asi los datos siempre
/// estan actualizados (no le pasamos el objeto entero).
/// Si se borra la partida cierra la pantalla devolviendo true, para que
/// la lista de antes sepa que tiene que recargar.
class DetalleScreen extends StatefulWidget {
  const DetalleScreen({super.key, required this.partidaId});

  final int partidaId;

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final _dao = PartidaDao();
  late Future<Partida?> _future;

  // para activar o no el boton de la papelera. Si la partida no existe
  // no tiene sentido poder borrarla
  bool _existe = false;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<Partida?> _cargar() async {
    final partida = await _dao.obtenerPorId(widget.partidaId);
    if (mounted) setState(() => _existe = partida != null);
    return partida; // puede ser null si alguien la borro
  }

  Future<void> _eliminar() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Eliminar partida',
      mensaje: 'Esta acción no se puede deshacer desde aquí.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
      icono: Icons.delete_outline,
    );
    if (!ok || !mounted) return;
    try {
      await _dao.eliminar(widget.partidaId);
      // volvemos atras devolviendo true (lo recoge historial o ranking)
      if (mounted) Navigator.pop(context, true);
    } on DatosException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partida #${widget.partidaId}'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _existe ? _eliminar : null, // null = boton desactivado
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: AsyncDataView<Partida?>(
        future: _future,
        onReintentar: () => setState(() => _future = _cargar()),
        builder: (context, partida) {
          // no hay partida con ese id
          if (partida == null) {
            return const EmptyStateView(
              icono: Icons.search_off,
              mensaje: 'La partida ya no existe',
            );
          }
          return _contenido(partida);
        },
      ),
    );
  }

  Widget _contenido(Partida p) {
    // una StatCard por cada dato de la partida
    final tarjetas = [
      StatCard(titulo: 'Jugador', valor: p.usuario ?? '-', icono: Icons.person_outline),
      StatCard(titulo: 'Puntuación', valor: '${p.puntuacion}', icono: Icons.star_outline),
      StatCard(titulo: 'Ficha máxima', valor: '${p.fichaMaxima}', icono: Icons.grid_view),
      StatCard(titulo: 'Movimientos', valor: '${p.movimientos}', icono: Icons.swipe),
      StatCard(
        titulo: 'Duración',
        valor: formatearDuracion(p.duracionSegundos),
        icono: Icons.timer_outlined,
      ),
      StatCard(
        titulo: 'Fecha',
        valor: formatearFecha(p.fecha),
        icono: Icons.calendar_today_outlined,
      ),
      StatCard(
        titulo: 'Tablero',
        valor: '${p.tamanoTablero}×${p.tamanoTablero}',
        icono: Icons.border_all,
      ),
    ];

    // LayoutBuilder nos da el ancho disponible: si la pantalla es ancha
    // (horizontal o tablet) pongo 2 columnas, si no 1
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth > 600 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(AppEspacios.m),
          children: [
            // ficha grande arriba con la animacion de aparecer
            Center(
              child: TileWidget(
                valor: p.fichaMaxima,
                lado: AppTamanos.fichaDetalle,
                esNueva: true,
              ),
            ),
            const SizedBox(height: AppEspacios.l),
            // GridView dentro de un ListView: hay que poner shrinkWrap y
            // quitarle el scroll, si no da error porque los dos quieren
            // hacer scroll y la altura seria infinita
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnas,
                mainAxisSpacing: AppEspacios.s,
                crossAxisSpacing: AppEspacios.s,
                mainAxisExtent: AppTamanos.altoStatCard, // alto fijo de cada tarjeta
              ),
              children: tarjetas,
            ),
          ],
        );
      },
    );
  }
}
