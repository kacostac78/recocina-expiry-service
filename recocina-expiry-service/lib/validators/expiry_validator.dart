/// VALIDADOR del microservicio de vencimientos.
///
/// Revisa que el JSON recibido tenga la forma correcta (campos
/// obligatorios, fecha con formato válido) antes de convertirlo en objetos
/// de dominio para el servicio.
library expiry_validator;

import '../services/expiry_service.dart';

class ValidationException implements Exception {
  final String mensaje;
  ValidationException(this.mensaje);

  @override
  String toString() => mensaje;
}

class ExpiryValidator {
  static List<InventoryItem> validarPayload(Map<String, dynamic> payload) {
    if (!payload.containsKey('items')) {
      throw ValidationException('El campo "items" es obligatorio');
    }

    final rawItems = payload['items'];
    if (rawItems is! List) {
      throw ValidationException('"items" debe ser una lista');
    }

    if (rawItems.isEmpty) {
      throw ValidationException('La lista de items no puede estar vacía');
    }

    final items = <InventoryItem>[];
    for (var i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      if (raw is! Map) {
        throw ValidationException('El item en la posición $i no es un objeto válido');
      }
      items.add(_validarItem(Map<String, dynamic>.from(raw), i));
    }

    return items;
  }

  static int validarDiasAlerta(String? valor) {
    if (valor == null || valor.isEmpty) return 3;
    final dias = int.tryParse(valor);
    if (dias == null || dias < 0) {
      throw ValidationException('El parámetro "dias" debe ser un entero no negativo');
    }
    return dias;
  }

  static InventoryItem _validarItem(Map<String, dynamic> item, int indice) {
    for (final campo in ['id', 'nombre', 'fechaVencimiento']) {
      if (!item.containsKey(campo) || item[campo] == null) {
        throw ValidationException('El item $indice: falta el campo "$campo"');
      }
    }

    final id = item['id'];
    final nombre = item['nombre'];
    final fechaRaw = item['fechaVencimiento'];

    if (id is! String || id.trim().isEmpty) {
      throw ValidationException('El item $indice: "id" debe ser un texto no vacío');
    }
    if (nombre is! String || nombre.trim().isEmpty) {
      throw ValidationException('El item $indice: "nombre" debe ser un texto no vacío');
    }
    if (fechaRaw is! String) {
      throw ValidationException(
          'El item $indice: "fechaVencimiento" debe ser un texto (ej. 2026-10-22)');
    }

    final fecha = DateTime.tryParse(fechaRaw);
    if (fecha == null) {
      throw ValidationException(
          'El item $indice: "fechaVencimiento" no tiene un formato de fecha válido');
    }

    return InventoryItem(id: id, nombre: nombre, fechaVencimiento: fecha);
  }
}
