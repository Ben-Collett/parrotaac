import 'package:flutter/material.dart';
import 'package:parrotaac/backend/quick_store.dart';

ValueNotifier<T> generateStoredValueNotifier<T>({
  required QuickStore storage,
  required String label,
  required T defaultValue,
  T? Function(dynamic)? decode,
  dynamic Function(T)? encode,
}) {
  T value;
  if (decode != null) {
    value = decode(storage[label]) ?? defaultValue;
  } else if (storage[label] is T) {
    value = storage[label];
  } else {
    value = defaultValue;
  }

  ValueNotifier<T> notifier = ValueNotifier(value);

  notifier.addListener(() {
    if (encode != null) {
      storage.writeData(label, encode(notifier.value));
    } else {
      storage.writeData(label, notifier.value);
    }
  });
  return notifier;
}

TextEditingController generateStoredTextController(
  QuickStore storage,
  String label,
) {
  TextEditingController out = TextEditingController(
    text: storage[label]?.toString(),
  );

  out.addListener(() async {
    if (storage[label] != out.text) {
      await storage.writeData(label, out.text);
    }
  });

  return out;
}
