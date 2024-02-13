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

class DeletedPhonelogsScreen extends StatefulWidget {
  @override
  _DeletedPhonelogsScreenState createState() => _DeletedPhonelogsScreenState();
}

class _DeletedPhonelogsScreenState extends State<DeletedPhonelogsScreen>
    with WidgetsBindingObserver {
  //Iterable<CallLogEntry> entries;

  CallLogs cl = new CallLogs();
  List<dynamic> nonMatchingLogs = [];

  Future<List<dynamic>> _getNonMatchingCallLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? uniqueNumber = prefs.getString('uniqueNumber');
    // prefs.remove('uniqueNumber');
    var apiUrl = Uri.parse(
        '${constants.apiUrl}/getDatabyUniqueNumber/$uniqueNumber');
    nonMatchingLogs.clear(); // Clearing the list before fetching new data
    try {
      var response = await http.get(apiUrl);
      var apiCallLogs = jsonDecode(response.body);
      var deviceCallLogs = await cl.getCallLogs();

      apiCallLogs["data"].forEach((apiLog) {
        bool matchFound = false;
        for (var entry in deviceCallLogs) {
          if (apiLog['number'] != null && apiLog['timestamp'] != null) {
            if (apiLog['number'].toString() == entry.number.toString() &&
                apiLog['timestamp'].toString() == entry.timestamp.toString()) {
              matchFound = true;
            }
          }
        }
        if (!matchFound) {
          if (apiLog['number'] != null &&
              apiLog['timestamp'] != null &&
              apiLog['duration'] != null) {
            nonMatchingLogs.add(apiLog);
          }
        }
      });
    } catch (e) {
      print('Error: $e');
    }
    // print(nonMatchingLogs);
    return nonMatchingLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deleted Call Logs"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Non-Matching Logs:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _getNonMatchingCallLogs(),
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
