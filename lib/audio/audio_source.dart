import 'dart:convert';
import 'dart:typed_data';

abstract class AudioSource {}

class TTSSource extends AudioSource {
  final String value;
  TTSSource(this.value);
}

class AudioUrlSource extends AudioSource {
  final String url;
  AudioUrlSource(this.url);
}

class AudioByteSource extends AudioSource {
  Uint8List data;
  AudioByteSource(this.data);
  AudioByteSource.fromString(String raw) : this(Utf8Encoder().convert(raw));
}

class AudioFilePathSource extends AudioSource {
  final String path;
  AudioFilePathSource(this.path);
}
