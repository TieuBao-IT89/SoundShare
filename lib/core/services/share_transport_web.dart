import 'dart:js_interop';

@JS('navigator')
external ShareNavigator get navigator;

extension type ShareNavigator(JSObject _) implements JSObject {
  external JSPromise<JSAny?> share(ShareData data);
}

extension type ShareData._(JSObject _) implements JSObject {
  external factory ShareData({String url});
}

Future<bool> shareWeb(String link) async {
  try {
    await navigator.share(ShareData(url: link)).toDart;
    return true;
  } on Object {
    return false;
  }
}
