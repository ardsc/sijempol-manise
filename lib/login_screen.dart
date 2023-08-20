import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_login/flutter_login.dart';
import 'package:sijempol_manise/constants.dart';
import 'package:sijempol_manise/custom_route.dart';
import 'package:sijempol_manise/dashboard_screen.dart';
import 'package:sijempol_manise/users.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class LoginScreen extends StatelessWidget {
  static const routeName = '/auth';

  const LoginScreen({Key? key}) : super(key: key);

  // Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);
  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 1);

  Future<void> _jwt(String jwt) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    await pref.setString('jwt', jwt);
    await pref.setBool('is_login', true);
  }

  Future<String?> _loginUser(LoginData data) {
    return Future.delayed(loginTime).then((_) async {
      final response = await http.post(Uri.parse(Constants.loginUrl),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'tahun': DateTime.now().year,
            'username': data.name,
            'password': data.password,
          }));

      if (200 == response.statusCode) {
        Map<String, dynamic> result = jsonDecode(response.body);

        if ('success' == result['status']) {
          _jwt(result['cookie']['sijempolmanise']);

          return null;
        } else if ('error' == result['status']) {
          if (result['errors'].containsKey('username')) {
            return result['errors']['username'].toString();
          }

          if (result['errors'].containsKey('password')) {
            return result['errors']['password'].toString();
          }
        }
      }

      return response.statusCode.toString();
    });
  }

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) {
      if (!mockUsers.containsKey(name)) {
        return 'User not exists';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      // title: Constants.appName,
      logo: const AssetImage('assets/logo.png'),
      logoTag: Constants.logoTag,
      titleTag: Constants.titleTag,
      navigateBackAfterRecovery: true,
      messages: LoginMessages(
        userHint: 'Username',
      ),
      theme: LoginTheme(
        primaryColor: Colors.teal,
        accentColor: Colors.yellow,
        //   errorColor: Colors.deepOrange,
        //   pageColorLight: Colors.indigo.shade300,
        //   pageColorDark: Colors.indigo.shade500,
        //   logoWidth: 0.80,
        //   titleStyle: TextStyle(
        //     color: Colors.greenAccent,
        //     fontFamily: 'Quicksand',
        //     letterSpacing: 4,
        //   ),
        //   // beforeHeroFontSize: 50,
        //   // afterHeroFontSize: 20,
        //   bodyStyle: TextStyle(
        //     fontStyle: FontStyle.italic,
        //     decoration: TextDecoration.underline,
        //   ),
        //   textFieldStyle: TextStyle(
        //     color: Colors.orange,
        //     shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
        //   ),
        //   buttonStyle: TextStyle(
        //     fontWeight: FontWeight.w800,
        //     color: Colors.yellow,
        //   ),
        //   cardTheme: CardTheme(
        //     color: Colors.yellow.shade100,
        //     elevation: 5,
        //     margin: EdgeInsets.only(top: 15),
        //     shape: ContinuousRectangleBorder(
        //         borderRadius: BorderRadius.circular(100.0)),
        //   ),
        //   inputTheme: InputDecorationTheme(
        //     filled: true,
        //     fillColor: Colors.purple.withOpacity(.1),
        //     contentPadding: EdgeInsets.zero,
        //     errorStyle: TextStyle(
        //       backgroundColor: Colors.orange,
        //       color: Colors.white,
        //     ),
        //     labelStyle: TextStyle(fontSize: 12),
        //     enabledBorder: UnderlineInputBorder(
        //       borderSide: BorderSide(color: Colors.blue.shade700, width: 4),
        //       borderRadius: inputBorder,
        //     ),
        //     focusedBorder: UnderlineInputBorder(
        //       borderSide: BorderSide(color: Colors.blue.shade400, width: 5),
        //       borderRadius: inputBorder,
        //     ),
        //     errorBorder: UnderlineInputBorder(
        //       borderSide: BorderSide(color: Colors.red.shade700, width: 7),
        //       borderRadius: inputBorder,
        //     ),
        //     focusedErrorBorder: UnderlineInputBorder(
        //       borderSide: BorderSide(color: Colors.red.shade400, width: 8),
        //       borderRadius: inputBorder,
        //     ),
        //     disabledBorder: UnderlineInputBorder(
        //       borderSide: BorderSide(color: Colors.grey, width: 5),
        //       borderRadius: inputBorder,
        //     ),
        //   ),
        //   buttonTheme: LoginButtonTheme(
        //     splashColor: Colors.purple,
        //     backgroundColor: Colors.pinkAccent,
        //     highlightColor: Colors.lightGreen,
        //     elevation: 9.0,
        //     highlightElevation: 6.0,
        //     shape: BeveledRectangleBorder(
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        //     // shape: CircleBorder(side: BorderSide(color: Colors.green)),
        //     // shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
        //   ),
      ),
      userValidator: (value) {
        if (value!.isEmpty) {
          return 'Masukan username';
        }

        return null;
      },
      passwordValidator: (value) {
        if (value!.isEmpty) {
          return 'Masukan password';
        }

        return null;
      },
      onLogin: (loginData) {
        debugPrint('Login info');
        debugPrint('Name: ${loginData.name}');
        debugPrint('Password: ${loginData.password}');
        return _loginUser(loginData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          FadePageRoute(
            builder: (context) => const DashboardScreen(),
          ),
        );
      },
      onRecoverPassword: (name) {
        debugPrint('Recover password info');
        debugPrint('Name: $name');
        return _recoverPassword(name);
        // Show new password dialog
      },
    );
  }
}
