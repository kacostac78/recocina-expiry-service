import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/endpoints/expiry_endpoint.dart';

void main() async {
  final endpoint = ExpiryEndpoint();

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(endpoint.router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8082');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('recocina-expiry-service escuchando en el puerto ${server.port}');
}
