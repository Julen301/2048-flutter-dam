import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import 'empty_state_view.dart';

/// Gestiona los tres estados de un Future: cargando, error (con botón de
/// reintento) y datos. Mientras se recarga mantiene los datos anteriores
/// para que el RefreshIndicator no "salte".
class AsyncDataView<T> extends StatelessWidget {
  const AsyncDataView({
    super.key,
    required this.future,
    required this.builder,
    required this.onReintentar,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T datos) builder;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return EmptyStateView(
              icono: Icons.error_outline,
              mensaje: error is DatosException
                  ? error.mensaje
                  : 'Ha ocurrido un error inesperado',
              accion: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: Size.zero),
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            );
          }
          return builder(context, snapshot.data as T);
        }
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
