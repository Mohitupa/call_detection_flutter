import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'constant.dart' as constants;

class UniqueNumberForm extends StatefulWidget {
  @override
  _UniqueNumberFormState createState() => _UniqueNumberFormState();
}

class _UniqueNumberFormState extends State<UniqueNumberForm> {
  final TextEditingController _uniqueNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Number Form'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _uniqueNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter Number'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveUniqueNumber();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUniqueNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uniqueNumber', _uniqueNumberController.text);
    await prefs.setString('logStartDate', (DateTime.now()).toString());

    var data = [
      {'uniqueNumber': _uniqueNumberController.text}
    ];

    var url = Uri.parse(
        '${constants.apiUrl}/check-uniqueNumber?uniqueNumber=${_uniqueNumberController.text}');
    try {
      print(url);
      var responseGet = await http.get(url);
      var existingData = jsonDecode(responseGet.body);
      if (existingData['exists'] == false) {

        var urlStore = Uri.parse('${constants.apiUrl}/data');
        final response = await http.post(urlStore, body: data[0]);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Data stored successfully');
        } else {
          print('Failed to store data: ${response.statusCode}');
        }

      }
    } catch (e) {
      // Error occurred
      print('Error: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unique number saved successfully')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: 'Flutter Call Detection'),
      ),
    );
  }
}
