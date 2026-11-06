import 'package:http/http.dart' as http;

import 'upload_control.dart';

Future<http.Response> sendUpload(
  http.Client client,
  http.MultipartRequest request,
  UploadControl? control,
) async {
  control?.check();
  try {
    return await http.Response.fromStream(await client.send(request));
  } on http.RequestAbortedException {
    throw const UploadCancelled();
  }
}
