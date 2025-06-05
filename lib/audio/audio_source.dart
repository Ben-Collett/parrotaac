import 'dart:convert';
import 'dart:typed_data';

abstract class AudioSource {}

class TTSSource extends AudioSource {
  final String value;
  TTSSource(this.value);
  @override
  String toString() {
    return "TTSource($value)";
  }
}

class AudioUrlSource extends AudioSource {
  final String url;
  AudioUrlSource(this.url);

  @override
  String toString() {
    return "URLSource($url)";
  }
}

class AudioByteSource extends AudioSource {
  Uint8List data;
  AudioByteSource(this.data);
  AudioByteSource.fromString(String raw) : this(Utf8Encoder().convert(raw));
  @override
  String toString() {
    return "RawBytesSource($data)";
  }
}

class AudioFilePathSource extends AudioSource {
  final String path;
  AudioFilePathSource(this.path);
  @override
  String toString() {
    return "FileSource($path)";
  }
}
