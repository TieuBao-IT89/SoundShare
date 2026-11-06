import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/core/services/upload_control.dart';

void main() {
  test('Cancel aborts a pending transfer and is idempotent', () async {
    var aborts = 0;
    final control = UploadControl();
    control.abortTransport = () => aborts++;
    control.cancel();
    control.cancel();
    await control.aborted;
    expect(aborts, 1);
    expect(control.phase, UploadPhase.cancelled);
    expect(control.check, throwsA(isA<UploadCancelled>()));
  });
  test('Metadata confirmation cannot be presented as a cancelled upload', () {
    final control = UploadControl();
    control.confirming();
    control.cancel();
    expect(control.canCancel, isFalse);
    expect(control.isCancelled, isFalse);
    control.completed();
    expect(control.phase, UploadPhase.completed);
  });
}
