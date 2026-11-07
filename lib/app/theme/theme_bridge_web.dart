import 'dart:js_interop';

@JS('soundshareTheme.setMode')
external void _setMode(JSString mode);

@JS('globalThis.soundshareTheme')
external JSObject? get _theme;

void syncBrowserTheme(String mode) {
  if (_theme != null) _setMode(mode.toJS);
}
