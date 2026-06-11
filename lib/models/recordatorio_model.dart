class Recordatorio {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String disenadorId;
  final bool completado;

  Recordatorio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.disenadorId,
    required this.completado,
  });

  factory Recordatorio.fromRecord(Map<String, dynamic> record) {
    return Recordatorio(
      id: record['id'] ?? '',
      titulo: record['titulo'] ?? '',
      descripcion: record['descripcion'] ?? '',
      fecha: DateTime.tryParse(record['fecha']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      disenadorId: record['disenador_id'] ?? '',
      completado: record['completado'] == true,
    );
  }

  Map<String, dynamic> toCreateBody() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha.toIso8601String(),
      'disenador_id': disenadorId,
      'completado': completado,
    };
  }
}
