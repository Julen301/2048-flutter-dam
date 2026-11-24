/// Las paletas de colores que se pueden elegir en ajustes para las fichas.
/// Los colores de cada una estan en app_theme.dart.
///
/// Los identificadores (clasica, oceano...) no se cambian aunque las paletas
/// ahora sean otras: es lo que se guarda en shared_preferences (.name) y asi
/// la preferencia que ya tuviera guardada el usuario sigue funcionando.
enum PaletaFichas {
  clasica('Neón'),
  oceano('Aurora'),
  bosque('Jade'),
  atardecer('Lava');

  // enum con constructor: cada valor lleva el texto que se ve en pantalla
  const PaletaFichas(this.etiqueta);

  // nombre "bonito" con tildes para los ChoiceChip de ajustes
  // (el .name seria 'clasica' sin tilde, ese es el que se guarda)
  final String etiqueta;
}
