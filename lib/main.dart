import 'dart:convert';

import 'package:call_detection/audio_recorder.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'Already_logs_screen.dart';
import 'callLogs.dart';
import 'deletedphonelogs_screen.dart';
import 'phonelogs_screen.dart';
import 'unique_number_form.dart';
import 'package:camera/camera.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'constant.dart' as constants;
import 'package:http/http.dart' as http;

/// Defines a callback that will handle all background incoming events
@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
    PhoneStateBackgroundEvent event,
    String number,
    int duration,
    ) async {

  print(event);
  print(number);
  print(duration);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? uniqueNumber = prefs.getString('uniqueNumber');
  if(uniqueNumber != null) {
    try {
      DateTime now = DateTime.now();
      final callEntry = CallEntry(
        duration: duration.toString(),
        number: number,
        timestamp: convertToTimestamp(now.toString()).toString(),
        callType: event.toString().replaceAll("PhoneStateBackgroundEvent.", ""),
        name: '',
      );

      var returnVal = DataStorage.checkDataExists(callEntry as CallEntry);
      print(returnVal);
    } catch (e) {
      print('Error: $e');
    }
  }
}
int convertToTimestamp(String dateString) {
  DateTime dateTime = DateTime.parse(dateString);
  return dateTime.millisecondsSinceEpoch;
}


String? uniqueNumber;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.phone.request().isGranted;
  await PhoneStateBackground.checkPermission();
  PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
  // Check if the unique number is stored in local storage
  SharedPreferences prefs = await SharedPreferences.getInstance();
  uniqueNumber = prefs.getString('uniqueNumber');

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      child: OKToast(
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
                  // const Text(
                  //   "Call Recorder",
                  //   style: TextStyle(
                  //     color: Colors.grey,
                  //     fontWeight: FontWeight.w800,
                  //   ),
                  // ),
                  // const SizedBox(
                  //   height: 20,
                  // ),
                  // IconButton(
                  //   onPressed: checkpermission_already_phone_logs,
                  //   icon: const Icon(Icons.phone_android_rounded),
                  //   iconSize: 42,
                  //   color: Colors.green,
                  // ),
                  // const SizedBox(
                  //   height: 5,
                  // ),
                  // const Text(
                  //   "Call Logs",
                  //   style: TextStyle(
                  //     color: Colors.green,
                  //     fontWeight: FontWeight.w800,
                  //   ),
                  // )
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
                child: Text("coming soon........"),
              ),
            )),
      ),
    );
  }
}

class CallEntry {
  final String? duration;
  final String? number;
  final String? timestamp;
  final String? callType;
  final String? name;

  CallEntry(
      {this.duration, this.number, this.timestamp, this.callType, this.name});

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    return CallEntry(
      duration: json['duration'] ?? 0,
      number: json['number'],
      timestamp: json['timestamp'] ?? 0,
      callType: json['callType'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'number': number,
      'timestamp': timestamp,
      'callType': callType,
      'name': name.toString(),
    };
  }
}

class DataStorage {
  static Future<List<Map<String, dynamic>>> storeData(
      List<CallEntry> dataList) async {
    print(dataList);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    List<Map<String, dynamic>> data =
        dataList.map((entry) => entry.toJson()).toList();
    print(data);
    var url = Uri.parse('${constants.apiUrl}/data');
    try {
      data[0]['uniqueNumber'] = uniqueNumber;
      final response = await http.post(url, body: data[0]);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Data stored successfully');
      } else {
        print('Failed to store data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return data;
  }

  static Future checkDataExists(CallEntry entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    var url = Uri.parse(
        '${constants.apiUrl}/check-existence?number=${entry.number}&timestamp=${entry.timestamp}&uniqueNumber=${uniqueNumber}');
    try {
      var response = await http.get(url);
      var existingData = jsonDecode(response.body);
      print(existingData);
      if (existingData['exists'] == false) {
        await storeData([entry]);
      }
    } catch (e) {
      // Error occurred
      print('Error: $e');
    }
  }
}
