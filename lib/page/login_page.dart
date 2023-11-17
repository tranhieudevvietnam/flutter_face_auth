import 'package:face_auth_flutter/page/face_recognition/camera_page.dart';
import 'package:face_auth_flutter/utils/local_db.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'face_recognition/camera_register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    // printIfDebug(LocalDB.getUser().name);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);

          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Face Authentication"),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)),
                    child: Column(
                      children: [
                        const Text("Register"),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(fillColor: Colors.white, filled: true),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        buildButton(
                          text: 'Register',
                          icon: Icons.app_registration_rounded,
                          onClicked: () async {
                            if (controller.text.isNotEmpty == true) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RegisterScreen(
                                            name: controller.text,
                                          )));
                            } else {
                              showDialog(context: context, builder: (context) => const AlertDialog(content: Text('Please input name!')));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildButton(
                    text: 'Login',
                    icon: Icons.login,
                    onClicked: () async {
                      // final user = LocalDB.getUser().firstWhereOrNull((element) => element.name == controller.text);
                      // if (user != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FaceScanScreen()));
                      // } else {
                      //   showDialog(context: context, builder: (context) => const AlertDialog(content: Text('No user!')));
                      // }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onClicked,
  }) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          text,
          style: const TextStyle(fontSize: 20),
        ),
        onPressed: onClicked,
      );
}
