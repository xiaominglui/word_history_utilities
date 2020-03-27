@JS()
library chromeext;

import 'package:js/js.dart';
import 'dart:async';
import 'dart:js';
import 'dart:convert';
import 'package:js/js_util.dart' as js;

class Extension {
  static Future sendMessage(
      String extensionId, dynamic message, SendMessageOptions options) {
    Completer completer = new Completer();
    ChromeRuntimeApi.sendMessage(extensionId, message, jsify(options),
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

  static Future sendMessage2(
      String extensionId, dynamic message, SendMessageOptions options) {
    var completer = new ChromeCompleter.oneArg();

    ChromeRuntimeApi.sendMessage(
        extensionId, message, options, completer.callback);
    return completer.future;
  }

  static Future storageSyncSet(Map<String, dynamic> items) {
    var completer = new ChromeCompleter.noArgs();
    ChromeStorageSyncApi.set(items, completer.callback);
    return completer.future;
  }

  static Future storageSyncGet(dynamic keys) {
    var completer = new ChromeCompleter.oneArg();
    ChromeStorageSyncApi.get(keys, completer.callback);
    return completer.future;
  }

  static Future storageLocalSet(dynamic items) {
    var completer = new ChromeCompleter.noArgs();
    ChromeStorageLocalApi.set(items, completer.callback);
    return completer.future;
  }

  static Future storageLocalGet(dynamic keys) {
    var completer = new ChromeCompleter.oneArg();
    ChromeStorageLocalApi.get(keys, completer.callback);
    return completer.future;
  }
}

@JS('chrome.storage.sync')
class ChromeStorageSyncApi {
  external static set(dynamic items, [Function callback]);
  external static get(dynamic keys, Function callback(items));
  external static remove(dynamic keys, [Function callback]);
  external static clear([Function callback]);
}

@JS('chrome.storage.local')
class ChromeStorageLocalApi {
  external static set(dynamic items, [Function callback]);
  external static get(dynamic keys, Function callback(items));
  external static remove(dynamic keys, [Function callback]);
  external static clear([Function callback]);
}

@JS('chrome.storage.local.set')
external Future csls(Map<String, dynamic> items, [Function callback]);

@JS('chrome.storage.onChanged')
class ChromeStorageOnChangedApi {
  external static addListener(
      Function callback(Map<String, dynamic> changes, String areaName));
}

@JS()
@anonymous
class StorageChange {
  external dynamic get oldValue;
  external dynamic get newValue;
}

@JS('chrome.runtime') // Since Chrome 35.
class ChromeRuntimeApi {
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

class StorageArea extends ChromeObject {
  StorageArea();
  StorageArea.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  /**
   * Gets one or more items from storage.
   *
   * [keys] A single key to get, list of keys to get, or a dictionary specifying
   * default values (see description of the object).  An empty list or object
   * will return an empty result object.  Pass in `null` to get the entire
   * contents of storage.
   *
   * Returns:
   * Object with items in their key-value mappings.
   */
  Future get([dynamic keys]) {
    var completer = new ChromeCompleter.oneArg(mapify);
    jsProxy.callMethod('get', [jsify(keys), completer.callback]);
    return completer.future;
  }
}

Map mapify(JsObject obj) {
  if (obj == null) return null;
  return jsonDecode(stringify(obj));
}

class ChromeObject {
  final dynamic jsProxy;

  /**
   * Create a new instance of a `ChromeObject`, which creates and delegates to
   * a JsObject proxy.
   */
  ChromeObject() : jsProxy = new JsObject(context['Object']);

  /**
   * Create a new instance of a `ChromeObject`, which delegates to the given
   * JsObject proxy.
   */
  ChromeObject.fromProxy(this.jsProxy);

  JsObject toJs() => jsProxy;

  String toString() => jsProxy.toString();
}

/**
 * The abstract superclass of Chrome enums.
 */
abstract class ChromeEnum {
  final String value;

  const ChromeEnum(this.value);

  String toString() => value;
}

final JsObject _storage = context['chrome']['storage'];

String get syncStorage {
  JsObject ss = _storage['sync'];

}

final JsObject _runtime = context['chrome']['runtime'];

String get lastError {
  JsObject error = _runtime['lastError'];
  return error != null ? error['message'] : null;
}

/**
 * An object for handling completion callbacks that are common in the chrome.*
 * APIs.
 */
class ChromeCompleter {
  final Completer _completer = new Completer();
  Function _callback;

  ChromeCompleter.noArgs() {
    this._callback = allowInterop(([_]) {
      print('callback');
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        _completer.complete();
      }
    });
  }

  ChromeCompleter.oneArg([Function transformer]) {
    this._callback = allowInterop(([arg1]) {
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        if (transformer != null) {
          arg1 = transformer(arg1);
        }
        _completer.complete(arg1);
      }
    });
  }

  ChromeCompleter.twoArgs(Function transformer) {
    this._callback = allowInterop(([arg1, arg2]) {
      var le = lastError;
      if (le != null) {
        _completer.completeError(le);
      } else {
        _completer.complete(transformer(arg1, arg2));
      }
    });
  }

  Future get future => _completer.future;

  Function get callback => _callback;
}

dynamic jsify(dynamic obj) {
  if (obj == null || obj is num || obj is String) {
    return obj;
  } else if (obj is ChromeObject) {
    return obj.jsProxy;
  } else if (obj is ChromeEnum) {
    return obj.value;
  } else if (obj is Map) {
    // Do a deep convert.
    Map m = {};
    for (var key in obj.keys) {
      m[key] = jsify(obj[key]);
    }
    return new JsObject.jsify(m);
  } else if (obj is Iterable) {
    // Do a deep convert.
    return new JsArray.from(obj).map(jsify);
  } else {
    return obj;
  }
}

Object mapToJSObj(Map<dynamic,dynamic> a){
  var object = js.newObject();
  a.forEach((k, v) {
    var key = k;
    var value = v;
    js.setProperty(object, key, value);
  });
  return object;
}