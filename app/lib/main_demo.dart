import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'dominio/api_juego.dart';
import 'dominio/controlador.dart';
import 'dominio/puerto_push.dart';
import 'infra/almacen_prefs.dart';
import 'infra/api_http.dart';
import 'presentacion/vms.dart';

/// Arranque de demostración SIN Firebase, para probar la app en el navegador.
///
/// Usa el servidor real y un puerto de push que se comporta como "permiso
/// denegado". Es la degradación elegante del manual: sin push, la app sigue
/// jugando y le pregunta al cantor cada 5 s.
///
/// Con el cantor en modo dev (`npm run dev` en server/):
///   flutter run -d edge -t lib/main_demo.dart
/// La dirección del cantor se puede cambiar con
///   --dart-define=CANTOR=http://localhost:8080
const _cantor = String.fromEnvironment('CANTOR', defaultValue: 'http://localhost:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final almacen = AlmacenPrefs(await SharedPreferences.getInstance());
  // CANTOR=mismo-origen sirve cuando la página y el cantor salen del mismo lugar (proxy).
  final api = ApiHttp(_cantor == 'mismo-origen' ? Uri.base.origin : _cantor);
  final controlador = ControladorPartida(api: api, push: PuertoSinPush(), almacen: almacen);
  runApp(AppLoteria(vm: JuegoVm(controlador), crearCantor: () => CantorVm(api)));
}

/// Puerto de push "apagado": nunca hay permiso ni mensajes.
class PuertoSinPush implements PuertoPush {
  @override
  Future<PermisoPush> estadoPermiso() async => PermisoPush.denegado;
  @override
  Future<PermisoPush> pedirPermiso() async => PermisoPush.denegado;
  @override
  Future<DestinoPush?> obtenerDestino() async => null;
  @override
  Stream<DestinoPush> get destinoCambiado => const Stream.empty();
  @override
  Stream<MensajePush> get enPrimerPlano => const Stream.empty();
  @override
  Stream<MensajePush> get alAbrirDesdeNotificacion => const Stream.empty();
  @override
  Future<MensajePush?> mensajeInicial() async => null;
  @override
  Future<void> suscribirTema(String tema) async {}
  @override
  Future<void> desuscribirTema(String tema) async {}
}
