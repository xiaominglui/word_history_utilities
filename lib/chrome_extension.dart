@JS()
library chromeext;

import 'package:js/js.dart';
import 'dart:async';
// import 'dart:js';

class Extension {
  static Map lastError() {
    return ChromeRuntimeApi.lastError;
  }

  static Future sendMessage(
      String extensionId, dynamic message, SendMessageOptions options) {
    Completer completer = new Completer();
    ChromeRuntimeApi.sendMessage(extensionId, message, options,
        allowInterop(([var result]) {
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
class ChromeRuntimeApi {
  // Invokes the JavaScript getter `chrome.runtime.lastError`.
  external static Map get lastError;

  external static sendMessage(dynamic message,
      [String extensionId,
      SendMessageOptions options,
      Function responseCallback([result])]);
}

// Calls invoke JavaScript `JSON.stringify(obj)`.
@JS("JSON.stringify")
external String stringify(obj);

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
