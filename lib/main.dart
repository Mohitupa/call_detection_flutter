import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'deletedphonelogs_screen.dart';
import 'phonelogs_screen.dart';
import 'unique_number_form.dart';
import 'package:camera/camera.dart';
import 'package:oktoast/oktoast.dart';

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
        title: 'Flutter Call Detection',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: uniqueNumber != null
            ? MyHomePage(title: 'Flutter Call Detection')
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: (MediaQuery.of(context).size.height - 80) / 2,
              child: Column(
                children: [
                  const SizedBox(
                    height: 70,
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
                    height: 70,
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
