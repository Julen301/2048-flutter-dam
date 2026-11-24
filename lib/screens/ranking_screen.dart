import 'package:flutter/material.dart';

import '../data/partida_dao.dart';
import '../models/estadisticas.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';
import '../widgets/stat_card.dart';

// junta las 3 consultas de la pantalla en un solo objeto, asi solo
// necesito un Future para el AsyncDataView
class _DatosRanking {
  const _DatosRanking(this.globales, this.top10, this.porJugador);

  final EstadisticasGlobales globales;
  final List<Partida> top10;
  final List<EstadisticaJugador> porJugador;
}

/// Pantalla de ranking: estadisticas generales, top 10 y mejor
/// puntuacion de cada jugador.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _dao = PartidaDao();
  late Future<_DatosRanking> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_DatosRanking> _cargar() async {
    return _DatosRanking(
      await _dao.obtenerEstadisticasGlobales(),
      await _dao.obtenerTop10(),
      await _dao.obtenerEstadisticasPorJugador(),
    );
  }

  void _recargar() => setState(() => _future = _cargar());

  // para el RefreshIndicator (deslizar hacia abajo). Tiene que devolver un
  // Future para que la ruedita se quite cuando termine de cargar
  Future<void> _refrescar() async {
    _recargar();
    try {
      await _future;
    } catch (_) {
      // si falla no hago nada aqui, el error ya lo enseña AsyncDataView
    }
  }

  Future<void> _abrirDetalle(Partida partida) async {
    // detalle devuelve true si se ha borrado la partida
    // (no pongo <bool> en pushNamed porque la ruta se crea como dynamic
    // en routes.dart y daria error de tipos)
    final eliminada = await Navigator.pushNamed(
      context,
      AppRoutes.detalle,
      arguments: partida.id,
    );
    // si se borro, recargo para que desaparezca del ranking
    if (mounted && eliminada == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking y estadísticas')),
      body: AsyncDataView<_DatosRanking>(
        future: _future,
        onReintentar: _recargar,
        builder: (context, datos) => RefreshIndicator(
          onRefresh: _refrescar,
          // si no hay ninguna partida enseño el mensaje de vacio
          child: datos.globales.partidasJugadas == 0
              ? _vacio()
              : _contenido(datos),
        ),
      ),
    );
  }

  Widget _contenido(_DatosRanking datos) {
    final g = datos.globales;
    final tema = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // en pantalla ancha 3 columnas de tarjetas, en movil 2
        final columnas = constraints.maxWidth > 600 ? 3 : 2;
        return ListView(
          // AlwaysScrollable para que el RefreshIndicator funcione aunque
          // la lista sea corta y no haga falta scroll
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppEspacios.l),
          children: [
            const _Titulo('Estadísticas globales'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspacios.m),
              // igual que en detalle: GridView dentro de ListView con
              // shrinkWrap y sin scroll propio
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  mainAxisSpacing: AppEspacios.s,
                  crossAxisSpacing: AppEspacios.s,
                  mainAxisExtent: AppTamanos.altoStatCard,
                ),
                children: [
                  StatCard(
                    titulo: 'Partidas',
                    valor: '${g.partidasJugadas}',
                    icono: Icons.sports_esports_outlined,
                  ),
                  StatCard(
                    titulo: 'Máxima',
                    valor: '${g.puntuacionMaxima}',
                    icono: Icons.emoji_events_outlined,
                  ),
                  StatCard(
                    titulo: 'Media',
                    valor: g.puntuacionMedia.toStringAsFixed(0), // sin decimales
                    icono: Icons.functions,
                  ),
                  StatCard(
                    titulo: 'Ficha máx.',
                    valor: '${g.fichaMaxima}',
                    icono: Icons.grid_view,
                  ),
                  StatCard(
                    titulo: 'Tiempo total',
                    valor: formatearDuracion(g.tiempoTotalSegundos),
                    icono: Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            const _Titulo('Top 10'),
            // uso for con indice porque necesito la posicion (i + 1)
            for (var i = 0; i < datos.top10.length; i++)
              PartidaListItem(
                partida: datos.top10[i],
                posicion: i + 1,
                onTap: () => _abrirDetalle(datos.top10[i]),
              ),
            const _Titulo('Por jugador'),
            Card(
              child: Column(
                children: [
                  for (final j in datos.porJugador)
                    ListTile(
                      // circulo con la inicial del jugador
                      leading: CircleAvatar(
                        backgroundColor: tema.colorScheme.secondaryContainer,
                        child: Text(
                          // si el nombre viniera vacio .first daria error, pongo "?"
                          j.usuario.isEmpty
                              ? '?'
                              : j.usuario.characters.first.toUpperCase(),
                          style: TextStyle(
                              color: tema.colorScheme.onSecondaryContainer),
                        ),
                      ),
                      title: Text(j.usuario),
                      // "1 partida" o "3 partidas"
                      subtitle: Text(
                          '${j.partidas} ${j.partidas == 1 ? 'partida' : 'partidas'}'),
                      trailing: Text(
                        '${j.mejorPuntuacion} pts',
                        style: tema.textTheme.titleMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _vacio() {
    // el RefreshIndicator necesita algo con scroll, por eso meto el
    // EmptyStateView en un SingleChildScrollView con la altura de la pantalla
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const EmptyStateView(
            icono: Icons.leaderboard_outlined,
            mensaje: 'Aún no hay partidas para el ranking',
            detalle: 'Las estadísticas aparecerán al terminar la primera partida.',
          ),
        ),
      ),
    );
  }
}

// titulo de cada bloque (Estadisticas globales, Top 10, Por jugador)
class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspacios.m, AppEspacios.l, AppEspacios.m, AppEspacios.s),
      child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
