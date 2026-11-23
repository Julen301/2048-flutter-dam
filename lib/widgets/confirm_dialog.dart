import 'package:flutter/material.dart';

/// Un boton del ConfirmDialog: el texto que se ve y el valor que devuelve
/// el dialogo si se pulsa.
/// Es generico (T) para poder devolver bool, un enum, etc.
class OpcionDialogo<T> {
  const OpcionDialogo({
    required this.texto,
    required this.valor,
    this.principal = false,
    this.destructiva = false,
  });

  final String texto;
  final T valor;
  final bool principal; // true = boton relleno (el importante)
  final bool destructiva; // true = se pinta en rojo (borrar, salir sin guardar...)
}

/// Dialogo de confirmacion que reutilizamos en toda la app: borrar partida,
/// borrar historial, reiniciar, salir del juego (este tiene 3 opciones), etc.
class ConfirmDialog<T> extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.opciones,
    this.icono,
  });

  final String titulo;
  final String mensaje;
  final List<OpcionDialogo<T>> opciones;
  final IconData? icono;

  /// Para el caso normal de Aceptar / Cancelar.
  /// Devuelve true solo si se pulsa confirmar. Si se cancela o se cierra
  /// tocando fuera devuelve false.
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Aceptar',
    String textoCancelar = 'Cancelar',
    bool destructivo = false,
    IconData? icono,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog<bool>(
        titulo: titulo,
        mensaje: mensaje,
        icono: icono,
        opciones: [
          OpcionDialogo(texto: textoCancelar, valor: false),
          OpcionDialogo(
            texto: textoConfirmar,
            valor: true,
            principal: true,
            destructiva: destructivo,
          ),
        ],
      ),
    );
    // showDialog devuelve null si se cierra tocando fuera, lo tratamos como "no"
    return resultado ?? false;
  }

  /// Para cuando hay mas de dos opciones (por ejemplo al salir del juego:
  /// guardar y salir / salir sin guardar / cancelar).
  /// Aqui si puede devolver null si se toca fuera, eso lo mira quien lo llama.
  static Future<R?> elegir<R>(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required List<OpcionDialogo<R>> opciones,
    IconData? icono,
  }) {
    return showDialog<R>(
      context: context,
      builder: (_) => ConfirmDialog<R>(
        titulo: titulo,
        mensaje: mensaje,
        opciones: opciones,
        icono: icono,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: icono == null ? null : Icon(icono),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        // un boton por cada opcion. La principal es FilledButton y el resto TextButton
        for (final opcion in opciones)
          if (opcion.principal)
            FilledButton(
              // Size.zero porque en el tema los FilledButton ocupan todo el
              // ancho, y dentro del dialogo quedaba mal
              style: opcion.destructiva
                  ? FilledButton.styleFrom(
                      backgroundColor: esquema.error,
                      foregroundColor: esquema.onError,
                      minimumSize: Size.zero,
                    )
                  : FilledButton.styleFrom(minimumSize: Size.zero),
              // cierra el dialogo y devuelve el valor de la opcion
              onPressed: () => Navigator.pop(context, opcion.valor),
              child: Text(opcion.texto),
            )
          else
            TextButton(
              style: opcion.destructiva
                  ? TextButton.styleFrom(foregroundColor: esquema.error)
                  : null,
              onPressed: () => Navigator.pop(context, opcion.valor),
              child: Text(opcion.texto),
            ),
      ],
    );
  }
}
