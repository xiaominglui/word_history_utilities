@JS()
library webext.js.runtime;

import 'package:js/js.dart';

@JS()
abstract class Runtime {
  Object getManifest();
  external void sendMessage(String extensionId, Object message, SendMessageOptions options, void callback(dynamic response));
}

@JS()
@anonymous
class SendMessageOptions {
  external bool get includeTlsChannelId;

  external factory SendMessageOptions({bool includeTlsChannelId});
}


