import 'dart:async';

enum UploadPhase { sending, confirming, completed, cancelled }

class UploadCancelled implements Exception {
  const UploadCancelled();
}

class UploadControl {
  UploadControl({this.onProgress, this.onPhase});
  final void Function(int loaded, int total)? onProgress;
  final void Function(UploadPhase phase)? onPhase;
  final _aborted = Completer<void>();
  Future<void> get aborted => _aborted.future;
  bool get isCancelled => _aborted.isCompleted;
  UploadPhase phase = UploadPhase.sending;
  void Function()? abortTransport;
  bool get canCancel => phase == UploadPhase.sending;
  void check() {
    if (isCancelled) throw const UploadCancelled();
  }

  void cancel() {
    if (!canCancel) return;
    phase = UploadPhase.cancelled;
    _aborted.complete();
    abortTransport?.call();
    onPhase?.call(phase);
  }

  void confirming() {
    check();
    phase = UploadPhase.confirming;
    onPhase?.call(phase);
  }

  void completed() {
    phase = UploadPhase.completed;
    onPhase?.call(phase);
  }
}
