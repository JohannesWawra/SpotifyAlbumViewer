import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class TinderAuth extends StatefulWidget {
  TinderAuth();

  @override
  _TinderAuthState createState() => _TinderAuthState();
}

class _TinderAuthState extends State<TinderAuth> {
  final String code_request_url = "api.gotinder.com";
  final String code_validate_url = "https://api.gotinder.com/v2/auth/sms/validate?auth_type=sms";
  final String token_url = "https://api.gotinder.com/v2/auth/login/sms";
  final Map<String,String> headers = {'user-agent': 'Tinder/11.4.0 (iPhone; iOS 12.4.1; Scale/2.00)', 'content-type': 'application/json'};
  String phoneNumber = "123";

  final phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose(){
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    phoneNumber = phoneNumberController.text;
    final data = {'phone_number': phoneNumber};
    final url = Uri.https(code_request_url, 'v2/auth/sms/send', {
      'auth_type': 'sms',
    });

    final encodedBody = data.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');

    final response = await http.post(
        url, headers: headers, body: encodedBody,
    );
    if(response.statusCode == 200){
      String smsSend = jsonDecode(response.body)['sms_sent'];
      if (smsSend == "True"){
        print("SUCCESS!");
      }
    } else {
      print(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter your Tinder-Phone-Number"
                )
              )
      ),
      body: Center(
      child: ElevatedButton(
          onPressed: () => login(), child: Text('Send SMS for Tinder-Login')),
    ),
    );
  }
}
