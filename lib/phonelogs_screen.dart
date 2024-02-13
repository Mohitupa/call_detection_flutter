import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:call_log/call_log.dart';
import './callLogs.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart' as constants;

class PhonelogsScreen extends StatefulWidget {
  @override
  _PhonelogsScreenState createState() => _PhonelogsScreenState();
}

class _PhonelogsScreenState extends State<PhonelogsScreen>
    with WidgetsBindingObserver {
  //Iterable<CallLogEntry> entries;
  CallLogs cl = new CallLogs();
  late Timer _timer;
  List<CallLogEntry>? previousLogs;

  late AppLifecycleState _notification;
  late Future<Iterable<CallLogEntry>> logs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    logs = cl.getCallLogs();
    // _getCallLogs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (AppLifecycleState.resumed == state) {
      setState(() {
        logs = cl.getCallLogs();
      });
    }
  }

  List<dynamic> LogsData = [];

  Future<List<dynamic>> _getCallLogs() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    String? logStart = prefs.getString('logStartDate');
    DateTime startLogDate = DateTime.parse(logStart!);
    print("logStart$logStart");//2024-02-09 15:00:50.076778
    // prefs.remove('uniqueNumber');
    var apiUrl = Uri.parse('${constants.apiUrl}/getDatabyUniqueNumber/$uniqueNumber');
    LogsData.clear();
    try {
      var response = await http.get(apiUrl);
      var apiCallLogs = jsonDecode(response.body);
      print(apiCallLogs);
      var deviceCallLogs = await cl.getCallLogs();

      Iterable<CallLogEntry> entries = await CallLog.query(
        dateFrom: startLogDate.millisecondsSinceEpoch,
      );

      // entries = entries.where((entry) => entry.callType == CallType.incoming || entry.callType == CallType.outgoing);


      for (var entry in entries) {
          final callEntry = CallEntry(
            duration: entry.duration.toString(),
            number: entry.number,
            timestamp: entry.timestamp.toString(),
            callType: entry.callType.toString(),
            name: entry.name,
          );

          var returnVal = DataStorage.checkDataExists(callEntry as CallEntry);
          print(returnVal);
        }
      LogsData = apiCallLogs["data"];
    } catch (e) {
      List<CallEntry> dataList = [];

      Iterable<CallLogEntry> entries = await CallLog.query(
        dateFrom: startLogDate.millisecondsSinceEpoch,
      );

      for (var entry in entries) {
        final callEntry = CallEntry(
          duration: entry.duration.toString(),
          number: entry.number,
          timestamp: entry.timestamp.toString(),
          callType: entry.callType.toString(),
          name: entry.name,
        );
        dataList.add(callEntry);
      }
      await writeDataToFile(dataList);

      // Directory directory = await getApplicationDocumentsDirectory();
      // String jsonString = await rootBundle.loadString('${directory.path}/call_log.json');
      // print("$jsonString--------------------------");
      // print(JsonDecoder(jsonString));
      print('Error: $e');
    }
    // print(LogsData);
    return LogsData;
  }

  Future<void> writeDataToFile(List<CallEntry> dataList) async {

    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/call_log.json';
      String jsonData = jsonEncode(dataList.map((entry) => entry.toJson()).toList());
      File file = File(filePath);
      print("$filePath");
      await file.writeAsString(jsonData);
      print('Data written to file successfully');
    } catch (e) {
      print('Error writing data to file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone"),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _getCallLogs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data?.length,
                    itemBuilder: (context, index) {
                      final log = snapshot.data?[index];
                      return Card(
                        child: ListTile(
                          title: Text('Number: ${log['number']}'),
                          subtitle: Text(
                            'Date/Time: ${DateTime.fromMillisecondsSinceEpoch(log['timestamp'] ?? 0)} \nid: ${log['id']} | Duration: ${log['duration']} | callType: ${ log['call_type'] != null ? log['call_type'].replaceAll("CallType.", ""): log['call_type']}',
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
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
      {this.duration,
      this.number,
      this.timestamp,
      this.callType,
      this.name});

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    List<Map<String, dynamic>> data =
        dataList.map((entry) => entry.toJson()).toList();
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

  static Future<bool> checkDataExists(CallEntry entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    var url = Uri.parse(
        '${constants.apiUrl}/check-existence?number=${entry.number}&timestamp=${entry.timestamp}&uniqueNumber=${uniqueNumber}');
    try {
      var response = await http.get(url);
      var existingData = jsonDecode(response.body);
      if (existingData['exists'] == false) {
        await storeData([entry]);
      }
      return true;
    } catch (e) {
      // Error occurred
      print('Error: $e');
      return false;
    }
  }

  static Future<Object> getLogList(CallEntry entry) async {
    try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    var url = Uri.parse('${constants.apiUrl}/getDatabyUniqueNumber/$uniqueNumber');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> existingData = jsonDecode(response.body);
        return existingData;
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
