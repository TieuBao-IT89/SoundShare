import 'dart:js_interop';

import 'package:http/http.dart' as http;

import 'upload_control.dart';

@JS('soundshareUpload.send')
external _UploadHandle _send(
  JSString url,
  JSString token,
  JSString contentType,
  JSUint8Array bytes,
  JSFunction progress,
);

extension type _UploadHandle(JSObject _) implements JSObject {
  external JSPromise<_UploadResult> get promise;
  external void abort();
}

extension type _UploadResult(JSObject _) implements JSObject {
  external JSNumber get status;
  external JSString get body;
}

Future<http.Response> sendUpload(
  http.Client client,
  http.MultipartRequest request,
  UploadControl? control,
) async {
  if (control == null) {
    return http.Response.fromStream(await client.send(request));
  }
  control.check();
  final bytes = await request.finalize().toBytes();
  control.check();
  final handle = _send(
    request.url.toString().toJS,
    (request.headers['Authorization'] ?? '').replaceFirst('Bearer ', '').toJS,
    (request.headers['content-type'] ?? '').toJS,
    bytes.toJS,
    ((JSNumber loaded, JSNumber total) {
      control.onProgress?.call(loaded.toDartInt, total.toDartInt);
    }).toJS,
  );
  control.abortTransport = () => handle.abort();
  try {
    final result = await handle.promise.toDart;
    return http.Response(
      result.body.toDart,
      result.status.toDartInt,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (_) {
    if (control.isCancelled) throw const UploadCancelled();
    rethrow;
  } finally {
    control.abortTransport = null;
  }
}
