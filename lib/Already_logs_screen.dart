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

class AlreadyPhonelogsScreen extends StatefulWidget {
  @override
  _AlreadyPhonelogsScreenState createState() => _AlreadyPhonelogsScreenState();
}

class _AlreadyPhonelogsScreenState extends State<AlreadyPhonelogsScreen>
    with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone"),
      ),
      body: Column(
        children: [
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
                          onLongPress: () =>{},
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
  static Future<Map<String, dynamic>> storeData(CallEntry entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    Map<String, dynamic> data = entry.toJson();
    var url = Uri.parse('${constants.apiUrl}/data');
    try {
      data['uniqueNumber'] = uniqueNumber;
      final response = await http.post(url, body: data);
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
        await storeData([entry] as CallEntry);
      }
      return true;
    } catch (e) {
      // Error occurred
      print('Error: $e');
      return false;
    }
  }
}
