import 'dart:collection';

import 'package:openboard_wrapper/button_data.dart';
import 'package:openboard_wrapper/color_data.dart';
import 'package:parrotaac/audio/audio_source.dart';
import 'package:parrotaac/audio/prefered_audio_source.dart';
import 'package:parrotaac/backend/project/parrot_project.dart';

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

extension UpdateFromDiff on ButtonData {
  void merge(Map<String, dynamic> diff, {ParrotProject? project}) {
    if (diff.containsKey(ButtonData.labelKey)) {
      label = diff[ButtonData.labelKey];
    }

    if (diff.containsKey(ButtonData.voclizationKey)) {
      voclization = diff[ButtonData.voclizationKey];
    }

    if (diff.containsKey(ButtonData.bgColorKey)) {
      backgroundColor = ColorData.fromString(diff[ButtonData.bgColorKey]);
    }

    if (diff.containsKey(ButtonData.borderColorKey)) {
      borderColor = ColorData.fromString(diff[ButtonData.borderColorKey]);
    }

    if (diff.containsKey(ButtonData.actionKey)) {
      action = diff[ButtonData.actionKey];
    }

    if (diff.containsKey(ButtonData.actionsKey)) {
      actions = diff[ButtonData.actionsKey];
    }

    //TODO: really should log if the project is null
    if (diff.containsKey('load_board') && diff['load_board'] == null) {
      linkedBoard = null;
      loadBoardData = null;
    }

    if (diff['load_board'] is Map && project != null) {
      String? boardId = diff['load_board']['id'];
      if (boardId != null) {
        linkedBoard = project.findBoardById(boardId);
      }
    }

    Iterable<String> changedExtendedProperties =
        diff.keys.where((e) => e.startsWith('ext_'));
    for (String key in changedExtendedProperties) {
      if (diff[key] == null) {
        extendedProperties.remove(key);
      } else {
        extendedProperties[key] = diff[key];
      }
    }
  }
}
