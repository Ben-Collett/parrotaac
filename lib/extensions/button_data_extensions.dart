import 'dart:collection';

import 'package:openboard_wrapper/button_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';

import 'package:path/path.dart' as p;

const String preferredAudioSourceKey = "ext_preferred_audio_source";

extension ButtonDataExtension on ButtonData {
  AudioSource getSource({String? projectPath}) {
    AudioSource? source = _getAudioSource(
      preferredAudioSources: audioSourceTypeRanking,
      rootPath: projectPath,
    );
    TTSSource fallback = TTSSource(voclization ?? label ?? "");
    return source ?? fallback;
  }

  AudioSource? _getAudioSource(
      {required Iterable<PreferredAudioSourceType> preferredAudioSources,
      String? rootPath}) {
    for (PreferredAudioSourceType type in preferredAudioSources) {
      if (_validSource(type, rootPath)) {
        return _fromType(type, rootPath);
      }
    }
    return null;
  }

  AudioSource? _fromType(PreferredAudioSourceType type, String? rootPath) {
    if (type == PreferredAudioSourceType.tts) {
      return null;
    }
    if (type == PreferredAudioSourceType.mute) {
      return TTSSource("");
    }
    if (type == PreferredAudioSourceType.file) {
      return AudioFilePathSource(p.join(rootPath!, sound?.path!));
    }
    if (type == PreferredAudioSourceType.alternative) {
      if (sound?.data != null) {
        return AudioByteSource.fromString(sound!.data!.data);
      } else if (sound?.url != null) {
        return AudioUrlSource(sound!.url!);
      }
    }
    return null;
  }

  bool _validSource(PreferredAudioSourceType sourceType, String? rootPath) {
    if (sourceType == PreferredAudioSourceType.tts ||
        sourceType == PreferredAudioSourceType.mute ||
        sourceType == PreferredAudioSourceType.alternative) {
      return true;
    }
    bool checkRecordAndFileConditions = rootPath != null && sound?.path != null;
    return checkRecordAndFileConditions;
  }

  PreferredAudioSourceType get preferredAudioSourceType {
    return audioSourceTypeRanking.first;
  }

  set preferredAudioSourceType(PreferredAudioSourceType type) {
    extendedProperties[preferredAudioSourceKey] = type.toString();
  }

  Iterable<PreferredAudioSourceType> get audioSourceTypeRanking {
    LinkedHashSet<PreferredAudioSourceType> out = LinkedHashSet.identity();
    if (extendedProperties.containsKey(preferredAudioSourceKey)) {
      String? value = extendedProperties[preferredAudioSourceKey];
      final pType = PreferredAudioSourceType.values
          .where((t) => t.label == value)
          .firstOrNull;

      if (pType != null) {
        out.add(pType);
      }
    }

    if (sound?.data != null) {
      out.add(PreferredAudioSourceType.alternative);
    } else if (sound?.path != null) {
      out.add(PreferredAudioSourceType.file);
    } else if (sound?.url != null) {
      out.add(PreferredAudioSourceType.alternative);
    }
    out.add(PreferredAudioSourceType.tts);
    return out;
  }
}
