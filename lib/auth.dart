import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_market/components/basic_dialog.dart';
import 'package:flutter_market/main.dart'; // main.dart 파일을 import
import 'package:flutter_market/models/order.dart';
import 'package:intl/intl.dart';
import 'package:kpostal/kpostal.dart';

class AuthService {
  //이 인스턴스를 통해 Firebase 인증 기능(로그인, 로그아웃, 회원가입, 비밀번호 재설정 등)을 사용할 수 있습니다.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  //로그인 함수
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  //회원 가입 함수
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  //로그아웃 함수
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final database = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final formKey = GlobalKey<FormState>();

  TextEditingController buyerNameController = TextEditingController();
  TextEditingController buyerEmailController = TextEditingController();
  TextEditingController buyerPhoneController = TextEditingController();
  TextEditingController receiverZipController = TextEditingController();
  TextEditingController receiverAddress1Controller = TextEditingController();
  TextEditingController receiverAddress2Controller = TextEditingController();
  TextEditingController userPwdController = TextEditingController();
  TextEditingController userConfirmPwdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("회원가입"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              inputTextField(
                  currentController: buyerNameController,
                  currentHintText: "이름"),
              inputTextField(
                  currentController: buyerEmailController,
                  currentHintText: "이메일"),
              inputTextField(
                  currentController: userPwdController,
                  currentHintText: "비밀번호",
                  isObscure: true),
              inputTextField(
                  currentController: userConfirmPwdController,
                  currentHintText: "비밀번호 확인",
                  isObscure: true),
              inputTextField(
                  currentController: buyerPhoneController,
                  currentHintText: "전화번호"),
              receiverZipTextField(),
              inputTextField(
                  currentController: receiverAddress1Controller,
                  currentHintText: "기본 주소",
                  isReadOnly: true),
              inputTextField(
                  currentController: receiverAddress2Controller,
                  currentHintText: "상세 주소"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      List<int> bytes = utf8.encode(userPwdController.text);
                      //비밀번호 해쉬화
                      Digest hashPwd = sha256.convert(bytes);

                      String orderNo = "${DateFormat("yMdhms").format(DateTime.now())}-${DateTime.now().millisecond}";

                      ProductOrder productOrder = ProductOrder(
                        orderNo: orderNo,
                        buyerName: buyerNameController.text,
                        buyerEmail: buyerEmailController.text,
                        buyerPhone: buyerPhoneController.text,
                        receiverZip: receiverZipController.text,
                        receiverAddress1: receiverAddress1Controller.text,
                        receiverAddress2: receiverAddress2Controller.text,
                        userPwd: hashPwd.toString(),
                      );

                      try {
                        await database.collection("idpw").add(productOrder.toJson());
                        await auth.createUserWithEmailAndPassword(
                          email: buyerEmailController.text,
                          password: userPwdController.text,
                        );
                        showDialog(
                          context: context,
                          builder: (context) {
                            return BasicDialog(
                              content: "회원가입이 완료되었습니다.",
                              buttonText: "확인",
                              buttonFunction: () {
                                Navigator.of(context).pop(); // Close the dialog
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const AuthHome()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                            );
                          },
                        );
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return BasicDialog(
                              content: "회원가입 중 오류가 발생했습니다: $e",
                              buttonText: "닫기",
                              buttonFunction: () => Navigator.of(context).pop(),
                            );
                          },
                        );
                      }
                    }
                  },
                  child: const Text("회원가입"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget inputTextField({
    required TextEditingController currentController,
    required String currentHintText,
    int? currentMaxLength,
    bool isObscure = false,
    bool isReadOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        //입력폼 유효성 검사 및 비밀번호 일치 검사
        validator: (value) {
          if (value!.isEmpty) {
            return "내용을 입력해 주세요.";
          } else if (currentController == userConfirmPwdController &&
              userPwdController.text != userConfirmPwdController.text) {
            return "비밀번호가 일치하지 않습니다.";
          }
          return null;
        },
        controller: currentController,
        maxLength: currentMaxLength,
        obscureText: isObscure,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: currentHintText,
        ),
      ),
    );
  }

//import 'package:kpostal/kpostal.dart'; 주소 라이브러리 적용
  Widget receiverZipTextField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: receiverZipController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "우편번호",
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return KpostalView(callback: (Kpostal result) {
                      receiverZipController.text = result.postCode;
                      receiverAddress1Controller.text = result.address;
                    });
                  },
                ),
              );
            },
            child: const Text("우편 번호 찾기"),
          ),
        ],
      ),
    );
  }
}
