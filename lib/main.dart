import 'package:call_detection/audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Already_logs_screen.dart';
import 'deletedphonelogs_screen.dart';
import 'phonelogs_screen.dart';
import 'unique_number_form.dart';
import 'package:camera/camera.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

String? uniqueNumber;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the unique number is stored in local storage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uniqueNumber = prefs.getString('uniqueNumber');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Call Log',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: uniqueNumber != null
            ? MyHomePage(title: 'Call Log')
            : UniqueNumberForm(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  openPhonelogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhonelogsScreen(),
      ),
    );
  }

  openDeletedPhonelogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeletedPhonelogsScreen(),
      ),
    );
  }

  openAlreadyPhonelogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlreadyPhonelogsScreen(),
      ),
    );
  }

  openAudioRecorder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => audioRecorder(),
      ),
    );
  }

  checkpermission_phone_logs() async {
    if (await Permission.phone.request().isGranted) {
      openPhonelogs();
    } else {
      showToast("Provide Phone permission to make a call and view logs.",
          position: ToastPosition.bottom);
    }
  }

  checkpermission_deleted_phone_logs() async {
    if (await Permission.phone.request().isGranted) {
      openDeletedPhonelogs();
    } else {
      showToast("Provide Phone permission to make a call and view logs.",
          position: ToastPosition.bottom);
    }
  }

  checkpermission_already_phone_logs() async {
    if (await Permission.phone.request().isGranted) {
      openAlreadyPhonelogs();
    } else {
      showToast("Provide Phone permission to make a call and view logs.",
          position: ToastPosition.bottom);
    }
  }

  checkpermission_audio_phone_logs() async {
    // if (await Permission.audio.request().isGranted) {
      openAudioRecorder();
    // } else {
    //   showToast("Provide Phone permission to record a audio",
    //       position: ToastPosition.bottom);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Image(
                        image: AssetImage('assets/vector3.png'),
                      height: 80,
                    ),
                  ),
                  IconButton(
                    onPressed: checkpermission_phone_logs,
                    icon: const Icon(Icons.phone),
                    iconSize: 42,
                    color: Colors.blue,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "Call Logs",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  IconButton(
                    onPressed: checkpermission_deleted_phone_logs,
                    icon: const Icon(Icons.phone_disabled_rounded),
                    iconSize: 42,
                    color: Colors.red,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "Deleted Call Logs",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  IconButton(
                    onPressed: checkpermission_audio_phone_logs,
                    icon: const Icon(Icons.audiotrack),
                    iconSize: 42,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "Call Recorder",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  IconButton(
                    onPressed: checkpermission_already_phone_logs,
                    icon: const Icon(Icons.phone_android_rounded),
                    iconSize: 42,
                    color: Colors.green,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  const Text(
                    "Call Logs",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/vector3.png',
              height: 50,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(),
        child: Center(
          child: Center(
            child: SingleChildScrollView(
              child:Text("coming soon........"),
            ),
          )

        ),
      ),
    );
  }
}
