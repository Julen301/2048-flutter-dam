import 'package:flutter/material.dart';

import '../models/paleta_fichas.dart';

// En este archivo esta todo lo del estilo de la app: margenes, tamaños,
// animaciones, textos y colores. Asi no hay numeros sueltos por las pantallas
// y si queremos cambiar algo se cambia solo aqui.

/// Espaciados (padding, margin, SizedBox...) de menor a mayor.
abstract final class AppEspacios {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

/// Tamaños fijos y radios de las esquinas.
abstract final class AppTamanos {
  static const double radioFicha = 8;
  static const double radioTablero = 12;
  static const double radioTarjeta = 16;
  static const double separacionCeldas = 8;
  static const double anchoMaxTablero = 480; // para que en tablet no salga gigante
  static const double anchoMaxFormulario = 420;
  static const double fichaMiniatura = 44; // la ficha pequeña de las listas
  static const double fichaDetalle = 96; // la ficha grande de la pantalla detalle
  static const double iconoGrande = 72;
  static const double altoStatCard = 88;

  /// Pixeles minimos que hay que arrastrar el dedo para que cuente como
  /// movimiento. Si no, un toque normal movia las fichas.
  static const double umbralSwipe = 24;
}

/// Duraciones de las animaciones.
abstract final class AppDuraciones {
  static const Duration ficha = Duration(milliseconds: 140);
  static const Duration aparicion = Duration(milliseconds: 180);
}

/// Estilos de texto. Parten del textTheme del tema activo, por eso
/// necesitan el context.
abstract final class AppTextos {
  // el "2048" grande de la pantalla de inicio
  static TextStyle tituloJuego(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w900);

  // el texto pequeño de arriba del marcador (PUNTOS, MEJOR...)
  static TextStyle etiquetaMarcador(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );

  // el numero del marcador
  static TextStyle valorMarcador(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);

  /// Texto del numero de una ficha. Cuantas mas cifras tiene el numero
  /// mas pequeña es la letra, si no "2048" no cabe en la ficha.
  static TextStyle ficha(double lado, int valor, Color color) {
    final cifras = valor.toString().length;
    // el tamaño es un porcentaje del lado de la ficha
    final factor = switch (cifras) { 1 || 2 => 0.45, 3 => 0.36, 4 => 0.28, _ => 0.22 };
    return TextStyle(
      fontSize: lado * factor,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
}

/// Colores del tablero y las fichas.
/// Lo hago como ThemeExtension para meterlo dentro del ThemeData y que
/// cambie solo cuando se pasa de claro a oscuro. Desde un widget se usa
/// con FichasTheme.of(context).
@immutable
class FichasTheme extends ThemeExtension<FichasTheme> {
  const FichasTheme({
    required this.fondoTablero,
    required this.celdaVacia,
    required this.fichas,
    required this.textoOscuro,
    required this.textoClaro,
  });

  final Color fondoTablero;
  final Color celdaVacia;

  /// 12 colores: uno para cada ficha del 2 al 2048 (11) y el ultimo para
  /// las que pasan de 2048.
  final List<Color> fichas;
  final Color textoOscuro;
  final Color textoClaro;

  static FichasTheme of(BuildContext context) =>
      Theme.of(context).extension<FichasTheme>()!;

  /// Devuelve el color segun el valor de la ficha.
  /// Para sacar la posicion en la lista voy dividiendo entre 2 hasta
  /// llegar a 2: 2 -> 0, 4 -> 1, 8 -> 2 ... 2048 -> 10.
  Color colorFicha(int valor) {
    if (valor <= 0) return celdaVacia; // 0 = celda vacia
    var indice = 0;
    var v = valor;
    while (v > 2) {
      v >>= 1; // es lo mismo que v = v ~/ 2
      indice++;
    }
    // clamp para que 4096, 8192... usen el ultimo color y no se salga de la lista
    return fichas[indice.clamp(0, fichas.length - 1)];
  }

  /// Si la ficha es clara pongo el texto oscuro y al reves, para que se lea bien.
  /// computeLuminance da un valor de 0 (negro) a 1 (blanco).
  Color colorTexto(int valor) {
    final fondo = colorFicha(valor);
    return fondo.computeLuminance() > 0.45 ? textoOscuro : textoClaro;
  }

  // copyWith y lerp son obligatorios al extender ThemeExtension

  @override
  FichasTheme copyWith({
    Color? fondoTablero,
    Color? celdaVacia,
    List<Color>? fichas,
    Color? textoOscuro,
    Color? textoClaro,
  }) {
    return FichasTheme(
      fondoTablero: fondoTablero ?? this.fondoTablero,
      celdaVacia: celdaVacia ?? this.celdaVacia,
      fichas: fichas ?? this.fichas,
      textoOscuro: textoOscuro ?? this.textoOscuro,
      textoClaro: textoClaro ?? this.textoClaro,
    );
  }

  // lerp sirve para que al cambiar de tema los colores pasen poco a poco
  // de uno a otro (t va de 0 a 1) en vez de cambiar de golpe
  @override
  FichasTheme lerp(ThemeExtension<FichasTheme>? other, double t) {
    if (other is! FichasTheme) return this;
    return FichasTheme(
      fondoTablero: Color.lerp(fondoTablero, other.fondoTablero, t)!,
      celdaVacia: Color.lerp(celdaVacia, other.celdaVacia, t)!,
      fichas: List.generate(
        fichas.length,
            (i) => Color.lerp(fichas[i], other.fichas[i], t)!,
      ),
      textoOscuro: Color.lerp(textoOscuro, other.textoOscuro, t)!,
      textoClaro: Color.lerp(textoClaro, other.textoClaro, t)!,
    );
  }
}

/// Crea el tema claro y el oscuro. Se usan en app.dart (theme y darkTheme).
abstract final class AppTheme {
  /// Colores de cada paleta en modo claro, en orden: 2, 4, 8 ... 2048 y
  /// el ultimo para las fichas mayores de 2048.
  static const Map<PaletaFichas, List<Color>> _paletas = {
    PaletaFichas.clasica: [
      Color(0xFFEEE4DA), Color(0xFFEDE0C8), Color(0xFFF2B179), Color(0xFFF59563),
      Color(0xFFF67C5F), Color(0xFFF65E3B), Color(0xFFEDCF72), Color(0xFFEDCC61),
      Color(0xFFEDC850), Color(0xFFEDC53F), Color(0xFFEDC22E), Color(0xFF3C3A32),
    ],
    PaletaFichas.oceano: [
      Color(0xFFE0F2F1), Color(0xFFB2DFDB), Color(0xFF80CBC4), Color(0xFF4DD0E1),
      Color(0xFF26C6DA), Color(0xFF00ACC1), Color(0xFF0097A7), Color(0xFF00838F),
      Color(0xFF1E88E5), Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF1A237E),
    ],
    PaletaFichas.bosque: [
      Color(0xFFF1F8E9), Color(0xFFDCEDC8), Color(0xFFC5E1A5), Color(0xFFAED581),
      Color(0xFF9CCC65), Color(0xFF8BC34A), Color(0xFF7CB342), Color(0xFF689F38),
      Color(0xFF558B2F), Color(0xFF33691E), Color(0xFF2E7D32), Color(0xFF1B5E20),
    ],
    PaletaFichas.atardecer: [
      Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFB74D),
      Color(0xFFFF8A65), Color(0xFFFF7043), Color(0xFFF4511E), Color(0xFFE64A19),
      Color(0xFFD81B60), Color(0xFFAD1457), Color(0xFF880E4F), Color(0xFF4A148C),
    ],
  };

  // color base del que Material 3 saca el resto de colores de la app
  static const Color _semilla = Color(0xFFF59563);

  // lo usa ajustes para pintar el circulito de cada paleta
  static List<Color> coloresPaleta(PaletaFichas paleta) => _paletas[paleta]!;

  static ThemeData claro(PaletaFichas paleta) => _construir(Brightness.light, paleta);

  static ThemeData oscuro(PaletaFichas paleta) => _construir(Brightness.dark, paleta);

  // claro y oscuro se montan igual, solo cambian algunos colores
  static ThemeData _construir(Brightness brillo, PaletaFichas paleta) {
    final esOscuro = brillo == Brightness.dark;
    final esquema = ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo);
    final base = _paletas[paleta]!;

    // en modo oscuro oscurezco un poco las fichas (un 18% menos de luz)
    // porque con los colores originales deslumbraban mucho
    final fichas = esOscuro
        ? base.map((c) {
      final hsl = HSLColor.fromColor(c);
      return hsl.withLightness((hsl.lightness * 0.82).clamp(0.0, 1.0)).toColor();
    }).toList()
        : base;

    final fichasTheme = FichasTheme(
      fondoTablero: esOscuro ? const Color(0xFF2B2824) : const Color(0xFFBBADA0),
      celdaVacia: esOscuro ? const Color(0xFF3D3934) : const Color(0xFFCDC1B4),
      fichas: fichas,
      textoOscuro: const Color(0xFF3C3A32),
      textoClaro: const Color(0xFFF9F6F2),
    );

    // mismo borde redondeado para tarjetas y botones
    final redondeado = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTamanos.radioTarjeta),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brillo,
      extensions: [fichasTheme], // aqui se mete nuestro FichasTheme
      cardTheme: CardThemeData(
        shape: redondeado,
        margin: const EdgeInsets.symmetric(
          horizontal: AppEspacios.m,
          vertical: AppEspacios.xs,
        ),
      ),
      // botones a todo el ancho y con 52 de alto
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: redondeado,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: redondeado,
        ),
      ),
      // los SnackBar salen flotando en vez de pegados abajo
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
