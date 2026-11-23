import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lo que se ve cuando una lista esta vacia (o cuando hay un error).
/// Icono grande, un mensaje y opcionalmente un texto de detalle y un boton.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icono,
    required this.mensaje,
    this.detalle,
    this.accion,
  });

  final IconData icono;
  final String mensaje;
  final String? detalle; // texto secundario, opcional
  final Widget? accion; // por ejemplo el boton de "Reintentar" en AsyncDataView

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppEspacios.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: AppTamanos.iconoGrande,
              color: tema.colorScheme.outline, // gris, para que no llame tanto la atencion
            ),
            const SizedBox(height: AppEspacios.m),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            // con el if + ...[] solo se añaden estos widgets si hay detalle
            if (detalle != null) ...[
              const SizedBox(height: AppEspacios.s),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
            // lo mismo con el boton
            if (accion != null) ...[
              const SizedBox(height: AppEspacios.l),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
