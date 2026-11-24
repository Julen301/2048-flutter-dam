// Funciones para formatear duraciones y fechas.
// Las hago a mano para no tener que añadir el paquete intl solo para esto.

// pone un 0 delante si el numero tiene una cifra: 5 -> "05"
String _dos(int v) => v.toString().padLeft(2, '0');

/// Pasa segundos a texto tipo reloj.
/// Ejemplos: 75 -> "01:15", 3725 -> "1:02:05".
/// Las horas solo salen si hay alguna.
String formatearDuracion(int segundos) {
  final h = segundos ~/ 3600; // ~/ es division entera
  final m = (segundos % 3600) ~/ 60;
  final s = segundos % 60;
  return h > 0 ? '$h:${_dos(m)}:${_dos(s)}' : '${_dos(m)}:${_dos(s)}';
}

/// Fecha en formato dd/mm/aaaa hh:mm.
/// toLocal() porque la fecha puede venir en UTC y saldria con la hora mal.
String formatearFecha(DateTime fecha) {
  final l = fecha.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year} ${_dos(l.hour)}:${_dos(l.minute)}';
}
