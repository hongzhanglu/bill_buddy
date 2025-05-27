import 'package:bill_buddy_test/pages/equal_share.dart';
import 'package:bill_buddy_test/pages/split_by_order.dart';
import 'package:bill_buddy_test/pages/option.dart';
import 'package:bill_buddy_test/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    requestCamera();
  }

  void requestCamera() async {
    while (await _requestCameraPermission() != true) {}
  }

  void navigateToOptionPage(bool isEqualShare) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Option(
          onImagePicked: (xfile) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    isEqualShare ? EqualShare(xfile: xfile) : SplitByOrder(xfile: xfile),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/background.jpg',
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            color: Color.fromARGB(180, 255, 255, 255),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onTap: () => navigateToOptionPage(true),
                  childWidget: Text(
                    'Equal Share',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 30),
                Button(
                  onTap: () => navigateToOptionPage(false),
                  childWidget: Text(
                    'Split By Order',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Future<bool> _requestCameraPermission() async {
  PermissionStatus status = await Permission.camera.request();
  if (status.isGranted) {
    return true;
  } else if (status.isDenied) {
    return false;
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
    return false;
  }
  return false;
}
