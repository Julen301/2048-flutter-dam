// Representa un error controlado de la capa de datos con un mensaje legible para la interfaz
class DatosException implements Exception {
  const DatosException(this.mensaje, [this.causa]);

  final String mensaje; // Texto amigable para mostrar al usuario
  final Object? causa; // Error original por si hace falta depurar o registrar el fallo

  // Muestra el mensaje y, si existe, anade la causa tecnica entre parentesis
  @override
  String toString() => 'DatosException: $mensaje${causa != null ? ' ($causa)' : ''}';
}
