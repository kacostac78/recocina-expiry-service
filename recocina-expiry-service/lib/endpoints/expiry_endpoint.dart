/// ENDPOINT del microservicio de vencimientos.
///
/// Solo coordina: recibe el Request, delega a [ExpiryValidator] y al
/// servicio (`calcularAlertas`), y arma la Response.
library expiry_endpoint;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/expiry_service.dart';
import '../validators/expiry_validator.dart';

Response jsonResponse(Object data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

class ExpiryEndpoint {
  Router get router {
    final router = Router();

    router.get('/health', _health);
    router.post('/alertas', _calcularAlertas);

    return router;
  }

  Response _health(Request req) {
    return jsonResponse({'status': 'ok', 'service': 'recocina-expiry-service'});
  }

  Future<Response> _calcularAlertas(Request req) async {
    try {
      final diasAlerta =
          ExpiryValidator.validarDiasAlerta(req.url.queryParameters['dias']);

      final body = await req.readAsString();
      final payload = jsonDecode(body) as Map<String, dynamic>;

      // 1) Validación
      final items = ExpiryValidator.validarPayload(payload);

      // 2) Lógica de negocio (servicio)
      final alertas = calcularAlertas(items, diasAlerta: diasAlerta);

      // 3) Respuesta
      return jsonResponse({
        'alertas': alertas.map((a) => a.toJson()).toList(),
        'totalVencidos':
            alertas.where((a) => a.estado == EstadoVencimiento.vencido).length,
        'totalPorVencer': alertas
            .where((a) => a.estado == EstadoVencimiento.porVencer)
            .length,
      });
    } on ValidationException catch (e) {
      return jsonResponse({'error': e.mensaje}, status: 400);
    } on FormatException {
      return jsonResponse({'error': 'El cuerpo de la solicitud no es un JSON válido'},
          status: 400);
    } catch (e) {
      return jsonResponse({'error': 'Error interno: $e'}, status: 500);
    }
  }
}
