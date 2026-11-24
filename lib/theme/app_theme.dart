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
/// Estilo "Neón nocturno": esquinas muy redondeadas y algo mas de aire
/// entre celdas para que se vea el brillo de las fichas.
abstract final class AppTamanos {
  static const double radioFicha = 14;
  static const double radioTablero = 26;
  static const double radioTarjeta = 22;
  static const double radioCampo = 16; // campos de texto
  static const double separacionCeldas = 10;
  static const double altoBoton = 56;
  static const double anchoMaxTablero = 480; // para que en tablet no salga gigante
  static const double anchoMaxFormulario = 420;
  static const double fichaMiniatura = 44; // la ficha pequeña de las listas
  static const double fichaDetalle = 96; // la ficha grande de la pantalla detalle
  static const double iconoGrande = 72;
  static const double altoStatCard = 96; // con el icono en su cuadrado

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
  // el "2048" grande de inicio y login (se pinta con degradado en TituloJuego)
  static TextStyle tituloJuego(BuildContext context) =>
      Theme.of(context).textTheme.displayLarge!.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -3,
            height: 1,
          );

  // frase pequeña debajo del titulo
  static TextStyle lemaJuego(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

  // el texto pequeño de arriba del marcador (PUNTOS, MEJOR...)
  static TextStyle etiquetaMarcador(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          );

  // el numero del marcador
  static TextStyle valorMarcador(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          );

  /// Texto del numero de una ficha. Cuantas mas cifras tiene el numero
  /// mas pequeña es la letra, si no "2048" no cabe en la ficha.
  static TextStyle ficha(double lado, int valor, Color color) {
    final cifras = valor.toString().length;
    // el tamaño es un porcentaje del lado de la ficha
    final factor = switch (cifras) { 1 || 2 => 0.45, 3 => 0.36, 4 => 0.28, _ => 0.22 };
    return TextStyle(
      fontSize: lado * factor,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: color,
    );
  }
}

/// Colores fijos que no dependen del modo claro/oscuro.
abstract final class AppColores {
  /// Degradado de marca: titulo "2048", marcadores y borde del tablero.
  static const List<Color> degradadoMarca = [
    Color(0xFF7C5CFF), // violeta
    Color(0xFF1584B8), // azul turquesa (oscuro para que el texto blanco se lea)
  ];

  /// Medallas del ranking: oro, plata y bronce para los 3 primeros puestos.
  static const List<Color> medallas = [
    Color(0xFFFFC83D),
    Color(0xFFC9D1E6),
    Color(0xFFE0915A),
  ];

  /// Texto sobre los degradados de marca y las medallas.
  static const Color textoSobreMarca = Color(0xFFFFFFFF);
  static const Color textoSobreMedalla = Color(0xFF1A1640);
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

  /// Elige entre texto claro y oscuro el que mas contraste tenga con la
  /// ficha (formula de contraste de las pautas WCAG), para que se lea bien
  /// con cualquier paleta y en los dos modos.
  Color colorTexto(int valor) {
    final fondo = colorFicha(valor);
    return _contraste(textoOscuro, fondo) >= _contraste(textoClaro, fondo)
        ? textoOscuro
        : textoClaro;
  }

  /// Relacion de contraste entre dos colores: de 1 (iguales) a 21 (negro/blanco).
  /// computeLuminance da un valor de 0 (negro) a 1 (blanco).
  static double _contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final claro = la > lb ? la : lb;
    final oscuro = la > lb ? lb : la;
    return (claro + 0.05) / (oscuro + 0.05);
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
  /// Colores de cada paleta, en orden: 2, 4, 8 ... 2048 y el ultimo para
  /// las fichas mayores de 2048. Van de tonos suaves a muy saturados para
  /// que brillen sobre el tablero oscuro.
  static const Map<PaletaFichas, List<Color>> _paletas = {
    // Neón: lila -> cian -> azul -> violeta -> magenta -> dorado
    PaletaFichas.clasica: [
      Color(0xFFE9E6FF), Color(0xFFCFC7FF), Color(0xFF8EE6F7), Color(0xFF4FD1E8),
      Color(0xFF38B2FF), Color(0xFF5B7CFF), Color(0xFF8A5CFF), Color(0xFFB44DFF),
      Color(0xFFE040FB), Color(0xFFFF4FA3), Color(0xFFFFC83D), Color(0xFFFF6B3D),
    ],
    // Aurora: verdes agua -> turquesa -> azul -> purpura
    PaletaFichas.oceano: [
      Color(0xFFE3FFF6), Color(0xFFB8F5E0), Color(0xFF7EEBC6), Color(0xFF3DDBB0),
      Color(0xFF1EC8A5), Color(0xFF14B2B8), Color(0xFF1693C9), Color(0xFF2A6FDB),
      Color(0xFF4A4FE0), Color(0xFF6A3FD6), Color(0xFF8E2FD0), Color(0xFF2B1A6B),
    ],
    // Jade: verdes lima -> esmeralda -> azul petroleo
    PaletaFichas.bosque: [
      Color(0xFFEFFBEA), Color(0xFFD2F5C4), Color(0xFFA9EB93), Color(0xFF7FDD6A),
      Color(0xFF52CC4E), Color(0xFF2FB65A), Color(0xFF1E9E6B), Color(0xFF158577),
      Color(0xFF146B7D), Color(0xFF1A507A), Color(0xFF1E3A6E), Color(0xFF101B3B),
    ],
    // Lava: amarillo -> naranja -> rojo -> fucsia -> morado
    PaletaFichas.atardecer: [
      Color(0xFFFFF1D6), Color(0xFFFFE0A3), Color(0xFFFFC861), Color(0xFFFFAA3B),
      Color(0xFFFF8A2E), Color(0xFFFF6A2B), Color(0xFFFF4733), Color(0xFFF02D4E),
      Color(0xFFD61F69), Color(0xFFB0177E), Color(0xFF8A1287), Color(0xFF3A0B4A),
    ],
  };

  // color base del que Material 3 saca el resto de colores de la app
  static const Color _semilla = Color(0xFF6C4BFF);

  // Superficies propias (Material 3 por defecto da grises muy neutros)
  static const Color _fondoOscuro = Color(0xFF0E0F1F);
  static const Color _superficieOscura = Color(0xFF181A33);
  static const Color _superficieOscuraAlta = Color(0xFF22254A);
  static const Color _fondoClaro = Color(0xFFF5F3FF);
  static const Color _superficieClara = Color(0xFFFFFFFF);
  static const Color _superficieClaraAlta = Color(0xFFEAE6FF);

  // El tablero es oscuro en los dos modos (efecto "consola")
  static const Color _tableroOscuro = Color(0xFF14163A);
  static const Color _celdaOscura = Color(0xFF23275A);
  static const Color _tableroClaro = Color(0xFF262A5E);
  static const Color _celdaClara = Color(0xFF353A78);

  // lo usa ajustes para pintar el circulito de cada paleta
  static List<Color> coloresPaleta(PaletaFichas paleta) => _paletas[paleta]!;

  static ThemeData claro(PaletaFichas paleta) => _construir(Brightness.light, paleta);

  static ThemeData oscuro(PaletaFichas paleta) => _construir(Brightness.dark, paleta);

  // claro y oscuro se montan igual, solo cambian algunos colores
  static ThemeData _construir(Brightness brillo, PaletaFichas paleta) {
    final esOscuro = brillo == Brightness.dark;

    // Partimos de la semilla y forzamos nuestras superficies y acentos:
    // primario violeta, secundario cian y terciario magenta.
    final esquema = ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo)
        .copyWith(
      primary: esOscuro ? const Color(0xFF9D8BFF) : const Color(0xFF5B3DF5),
      onPrimary: esOscuro ? const Color(0xFF1A1050) : const Color(0xFFFFFFFF),
      secondary: esOscuro ? const Color(0xFF3DD9EB) : const Color(0xFF0B8FAD),
      tertiary: esOscuro ? const Color(0xFFFF6FB5) : const Color(0xFFD62A7A),
      surface: esOscuro ? _superficieOscura : _superficieClara,
      surfaceContainerLow: esOscuro ? _superficieOscura : _superficieClara,
      surfaceContainer: esOscuro ? _superficieOscura : _fondoClaro,
      surfaceContainerHigh: esOscuro ? _superficieOscuraAlta : _superficieClaraAlta,
      surfaceContainerHighest: esOscuro ? _superficieOscuraAlta : _superficieClaraAlta,
    );
    final fondo = esOscuro ? _fondoOscuro : _fondoClaro;
    final base = _paletas[paleta]!;

    // en modo oscuro bajo solo un poco la luz de las fichas (8%): sobre el
    // fondo casi negro tienen que seguir brillando
    final fichas = esOscuro
        ? base.map((c) {
            final hsl = HSLColor.fromColor(c);
            return hsl.withLightness((hsl.lightness * 0.92).clamp(0.0, 1.0)).toColor();
          }).toList()
        : base;

    final fichasTheme = FichasTheme(
      fondoTablero: esOscuro ? _tableroOscuro : _tableroClaro,
      celdaVacia: esOscuro ? _celdaOscura : _celdaClara,
      fichas: fichas,
      textoOscuro: const Color(0xFF1A1640),
      textoClaro: const Color(0xFFFFFFFF),
    );

    // tarjetas: esquinas grandes, sin sombra y con un borde muy fino
    final bordeTarjeta = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTamanos.radioTarjeta),
      side: BorderSide(color: esquema.outlineVariant.withValues(alpha: 0.5)),
    );
    // botones con forma de pildora
    const pildora = StadiumBorder();
    const tamanoBoton = Size.fromHeight(AppTamanos.altoBoton);
    const textoBoton = TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3);

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTamanos.radioCampo),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brillo,
      scaffoldBackgroundColor: fondo,
      extensions: [fichasTheme], // aqui se mete nuestro FichasTheme
      appBarTheme: AppBarTheme(
        backgroundColor: fondo,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: esquema.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: esquema.surface,
        shape: bordeTarjeta,
        margin: const EdgeInsets.symmetric(
          horizontal: AppEspacios.m,
          vertical: AppEspacios.xs,
        ),
      ),
      // botones a todo el ancho, en forma de pildora
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamanoBoton,
          shape: pildora,
          textStyle: textoBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamanoBoton,
          shape: pildora,
          textStyle: textoBoton,
          side: BorderSide(color: esquema.primary.withValues(alpha: 0.6), width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textoBoton),
      ),
      // campos de texto rellenos y sin linea, con borde de color al enfocar
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHigh,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquema.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: esquema.surfaceContainerHigh,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: esquema.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: esquema.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: esquema.primary.withValues(alpha: 0.18),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: esquema.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTamanos.radioTablero),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: esquema.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      // los SnackBar salen flotando y redondeados
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTamanos.radioCampo),
        ),
      ),
    );
  }
}
