import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parrotaac/audio_player.dart';
import 'package:parrotaac/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

const String recordTargetExtension = '.wav';
const String recordTargetFileName = 'record_test';
Future<Directory> recordTargetDir() async {
  return getTemporaryDirectory();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void playFromUrl() async {
    PreemptiveAudioPlayer().playFromUrl(
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
  }

  void playTTS() async {
    PreemptiveAudioPlayer().playTTS("hello world");
  }

  void playRecorded() async {
    Directory parentDir = await recordTargetDir();
    String filename =
        p.setExtension(recordTargetFileName, recordTargetExtension);
    PreemptiveAudioPlayer().playFromPath(p.join(parentDir.path, filename));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          children: [
            FloatingActionButton(
              onPressed: playTTS,
              child: Text("play tts"),
            ),
            FloatingActionButton(
              onPressed: playFromUrl,
              child: Text("play from url"),
            ),
            FloatingActionButton(
              onPressed: playRecorded,
              child: Text("play recorded"),
            ),
            RecordButton(),
          ],
        ),
      ),
    );
  }
}

class RecordButton extends StatefulWidget {
  const RecordButton({super.key});

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  final ValueNotifier<bool> _isRecording = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _isRecording,
        builder: (context, isRecording, child) {
          return TextButton(
              onPressed: () async {
                //print(isRecording);
                Directory targetDir = await recordTargetDir();
                if (isRecording) {
                  MyAudioRecorder().stop();
                  _isRecording.value = false;
                } else {
                  MyAudioRecorder().start(
                    parentDirectory: targetDir,
                    fileName: recordTargetFileName,
                    extension: recordTargetExtension,
                  );
                  _isRecording.value = true;
                }
              },
              child: Text(isRecording ? "stop" : "record"));
        });
  }

  @override
  void dispose() {
    _isRecording.dispose();
    super.dispose();
  }
}
