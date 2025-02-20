class AudioRecorder {
  void start() {}
  void stop({required String savePath}) {}

  void requestMicAccessIfNeeded() {}

  bool hasMicAccess() {
    return false;
  }

  bool get isRecording {
    return false;
  }
}
