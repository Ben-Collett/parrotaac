enum PreferredAudioSourceType {
  tts('TTS'),
  file("file"),
  alternative("alternative"),
  mute("mute");

  final String label;
  @override
  String toString() {
    return label;
  }

  const PreferredAudioSourceType(this.label);
}
