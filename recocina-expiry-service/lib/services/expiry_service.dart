/// SERVICIO (lógica de negocio) del microservicio de vencimientos.
///
/// No sabe nada de HTTP ni de JSON crudo — solo recibe objetos
/// [InventoryItem] ya validados (ver lib/validators/expiry_validator.dart).
library expiry_service;

class InventoryItem {
  final String id;
  final String nombre;
  final DateTime fechaVencimiento;

  InventoryItem({
    required this.id,
    required this.nombre,
    required this.fechaVencimiento,
  });
}

enum EstadoVencimiento { vencido, porVencer, vigente }

class AlertaItem {
  final String id;
  final String nombre;
  final DateTime fechaVencimiento;
  final int diasRestantes;
  final EstadoVencimiento estado;

  AlertaItem({
    required this.id,
    required this.nombre,
    required this.fechaVencimiento,
    required this.diasRestantes,
    required this.estado,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'fechaVencimiento': fechaVencimiento.toIso8601String(),
        'diasRestantes': diasRestantes,
        'estado': estado.name,
      };
}

/// [diasAlerta] es la ventana de días antes del vencimiento en la que
/// un alimento se considera "por vencer" (por defecto 3 días).
List<AlertaItem> calcularAlertas(
  List<InventoryItem> items, {
  int diasAlerta = 3,
}) {
  final hoy = DateTime.now();

  return items.map((item) {
    final diferencia = item.fechaVencimiento.difference(hoy).inDays;

    EstadoVencimiento estado;
    if (diferencia < 0) {
      estado = EstadoVencimiento.vencido;
    } else if (diferencia <= diasAlerta) {
      estado = EstadoVencimiento.porVencer;
    } else {
      estado = EstadoVencimiento.vigente;
    }

    return AlertaItem(
      id: item.id,
      nombre: item.nombre,
      fechaVencimiento: item.fechaVencimiento,
      diasRestantes: diferencia,
      estado: estado,
    );
  }).toList()
    ..sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));
}
