class OrdenItem {
  final String? id;

  // Relation: orden (id de la orden)
  final String ordenId;

  // Select single
  final String seccion;

  final String descripcion;

  final int cantidad;

  // Nombres de campos en PocketBase:
  // precio_unitario, subtotal, costo_laser, costo_material
  final double precioUnitario;
  final double subtotal;
  final double costoLaser;
  final double costoMaterial;

  // JSON libre
  final Map<String, dynamic> meta;

  OrdenItem({
    this.id,
    required this.ordenId,
    required this.seccion,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.costoLaser,
    required this.costoMaterial,
    Map<String, dynamic>? meta,
  }) : meta = meta ?? const {};

  factory OrdenItem.fromRecord(Map<String, dynamic> json) {
    return OrdenItem(
      id: json['id']?.toString(),
      ordenId: (json['orden'] ?? '').toString(),
      seccion: (json['seccion'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      cantidad: _toInt(json['cantidad'], fallback: 1),
      precioUnitario: _toDouble(json['precio_unitario']),
      subtotal: _toDouble(json['subtotal']),
      costoLaser: _toDouble(json['costo_laser']),
      costoMaterial: _toDouble(json['costo_material']),
      meta: (json['meta'] is Map<String, dynamic>)
          ? (json['meta'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toCreateBody() {
    return {
      'orden': ordenId, // relation
      'seccion': seccion,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'costo_laser': costoLaser,
      'costo_material': costoMaterial,
      'meta': meta,
    };
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}
