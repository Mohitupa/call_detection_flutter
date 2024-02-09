import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import './phone_textfield.dart';
import 'package:call_log/call_log.dart';
import './callLogs.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhonelogsScreen extends StatefulWidget {
  @override
  _PhonelogsScreenState createState() => _PhonelogsScreenState();
}

class _PhonelogsScreenState extends State<PhonelogsScreen>
    with WidgetsBindingObserver {
  //Iterable<CallLogEntry> entries;
  PhoneTextField pt = new PhoneTextField();
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
    checkDeletedCallLogs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void checkDeletedCallLogs() async {
    print("ruuning--------------------------");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone"),
      ),
      body: Column(
        children: [
          //TextField(controller: t1, decoration: InputDecoration(labelText: "Phone number", contentPadding: EdgeInsets.all(10), suffixIcon: IconButton(icon: Icon(Icons.phone), onPressed: (){print("pressed");})),keyboardType: TextInputType.phone, textInputAction: TextInputAction.done, onSubmitted: (value) => call(value),),
          FutureBuilder(
              future: logs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Iterable<CallLogEntry>? entries = snapshot.data;
                  return Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        final entry = entries?.elementAt(index);
                        final callType = entry?.callType!;

                        final callEntry = CallEntry(
                          duration: entry?.duration.toString(),
                          number: entry?.number,
                          timestamp: entry?.timestamp.toString(),
                          callType: entry?.callType.toString(),
                          name: entry?.name,
                        );

                        DataStorage.checkDataExists(callEntry as CallEntry);
                        // DataStorage.storeData([callEntry]);

                        return GestureDetector(
                          child: Card(
                            child: ListTile(
                              leading: cl
                                  .getAvator(callType!), // Using callType here
                              title: cl.getTitle(entry),
                              subtitle: Text(
                                "${cl.formatDate(DateTime.fromMillisecondsSinceEpoch(entry?.timestamp ?? 0))}\n${cl.getTime(entry?.duration ?? 0)}",
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: Icon(Icons.phone),
                                color: Colors.green,
                                onPressed: () {
                                  print(entry?.number);
                                  cl.call(entry?.number ?? "");
                                },
                              ),
                            ),
                          ),
                          onLongPress: () =>
                              pt.update(entry?.number.toString()),
                        );
                      },
                      itemCount:
                      entries?.length ?? 0, // Adding null check for entries
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              })
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
  final String? avatar;

  CallEntry(
      {this.duration,
        this.number,
        this.timestamp,
        this.callType,
        this.name,
        this.avatar});

  factory CallEntry.fromJson(Map<String, dynamic> json) {
    return CallEntry(
      duration: json['duration'] ?? 0,
      number: json['number'],
      timestamp: json['timestamp'] ?? 0,
      callType: json['callType'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'number': number,
      'timestamp': timestamp,
      'callType': callType,
      'name': name.toString(),
      'avatar': avatar.toString(),
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
    var url = Uri.parse('http://10.0.2.2:3000/api/data');
    try {
      data[0]['uniqueNumber'] = uniqueNumber;
      final response = await http.post(url, body: data[0]);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Data stored successfully');
      } else {
        print('Failed to store data: ${response.statusCode}');
      }
    } catch (e) {
      // Error occurred
      print('Error: $e');
    }
    return data;
  }

  static Future<bool> checkDataExists(CallEntry entry) async {
    var url = Uri.parse(
        'http://10.0.2.2:3000/api/check-existence?number=${entry.number}&timestamp=${entry.timestamp}');
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
    var url = Uri.parse('http://10.0.2.2:3000/api/data');
    try {
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
