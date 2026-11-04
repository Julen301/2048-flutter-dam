/// Las paletas de colores que se pueden elegir en ajustes para las fichas.
/// Los colores de cada una estan en app_theme.dart.
enum PaletaFichas {
  clasica('Clásica'),
  oceano('Océano'),
  bosque('Bosque'),
  atardecer('Atardecer');

  // enum con constructor: cada valor lleva el texto que se ve en pantalla
  const PaletaFichas(this.etiqueta);

  // nombre "bonito" con tildes para los ChoiceChip de ajustes
  // (el .name seria 'clasica' sin tilde, ese es el que se guarda)
  final String etiqueta;
}