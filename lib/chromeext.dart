@JS()
library chromeext;

import 'package:js/js.dart';
import 'dart:async';

class ChromeExt {
  static Future<dynamic> sendMessage(
      String extensionId, dynamic message, SendMessageOptions options) {
    Completer completer = new Completer();
    ChromeExtApi.sendMessage(extensionId, message, options,
        allowInterop(([dynamic result]) {
      if (result != null) {
        print('complete with result');
        completer.complete(result);
      } else {
        print('complete without result');
        completer.complete();
      }
    }));
    return completer.future;
  }
}

@JS('chrome.runtime')
class ChromeExtApi {
  external static sendMessage(dynamic message,
      [String extensionId,
      SendMessageOptions options,
      Function responseCallback([dynamic result])]);
}

@JS()
@anonymous
class SendMessageOptions {
  external bool get includeTlsChannelId;
  external factory SendMessageOptions({bool includeTlsChannelId});
}

@JS()
@anonymous
class SendMessageMessage {
  external bool get getHistory;
  external factory SendMessageMessage({bool getHistory});
}
