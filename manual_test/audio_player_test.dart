import 'package:flutter/material.dart';
import 'package:parrotaac/audio_player.dart';

void main() {
  runApp(const MyApp());
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

  //TODO: create a  manual test runner so I can create a test for play audio from path

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
          ],
        ),
      ),
    );
  }
}
