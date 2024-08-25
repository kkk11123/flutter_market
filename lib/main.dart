import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_market/auth.dart';
import 'package:flutter_market/constants.dart';
import 'package:flutter_market/item_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initiallizeSharedPreferences();
  

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: const AuthHome(),
    );
  }
}

class AuthHome extends StatefulWidget {
  const AuthHome({Key? key}) : super(key: key);

  @override
  _AuthHomeState createState() => _AuthHomeState();
}

class _AuthHomeState extends State<AuthHome> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카트라이더 마켓 로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await _authService.signInWithEmailAndPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                  print('Signed in: ${userCredential.user?.email}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ItemListPage()),
                  );
                } catch (e) {
                  print('Error: $e');
                }
              },
              child: const Text('로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              },
              child: const Text('회원가입'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                print('로그아웃');
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping App',
      home: ItemListPage(),
      debugShowCheckedModeBanner: false,      //디버그 패널 안 뜨게
      theme: ThemeData(       // 테마
        useMaterial3: true,       //material 버전 3 사용
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),    //파랑색을 기반으로 한 테마
      ),
    );
  }
