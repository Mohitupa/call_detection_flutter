import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class audioRecorder extends StatefulWidget {
  const audioRecorder({super.key});

  @override
  State<audioRecorder> createState() => _audioRecorderState();
}

class _audioRecorderState extends State<audioRecorder> {
  final audioRecord = AudioRecorder();
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    // audioRecord = Record();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    audioRecord.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        // await audioRecord.start(path: './');
        await audioRecord.start(const RecordConfig(), path: './assets/myFile.m4a');
        // final stream = await audioRecord.startStream(const RecordConfig(encoder: AudioEncoder.pcm16bits));
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print("Error:$e");
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      print("Path$path");

      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print("Error:$e");
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print("Error:$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Call Record"),
      ),
      body: Column(
        children: [
          if (isRecording) const Text("recording..............."),
          ElevatedButton(
            onPressed: isRecording ? stopRecording : startRecording,
            child:
                isRecording ? const Text("Stop Recording") : const Text("Start Recording"),
          ),
          SizedBox(
            height: 25,
          ),
          if (!isRecording && audioPath != null)
            ElevatedButton(
              onPressed: playRecording,
              child: const Text("Play Recording"),
            ),
        ],
      ),
    );
  }
}
