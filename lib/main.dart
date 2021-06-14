import 'dart:async';
import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Fica escutando os erros da thread em quer o app está rodando
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    // receber um par com o [Erro, Stack]
    final List<dynamic> errorAndStacktrace = pair;
    // Registra no firebase o erro
    await FirebaseCrashlytics.instance.recordError(
      errorAndStacktrace.first,
      errorAndStacktrace.last,
    );
  }).sendPort);
  // Executa o app dentro de uma zona segura, e caso aconteça um erro
  // Ele será reportado para o crashlytics
  runZonedGuarded(() async {
    runApp(MyApp());
  }, FirebaseCrashlytics.instance.recordError);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        user: {
          'id': '12314123123123123',
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title, required this.user})
      : super(key: key);
  final Map<String, dynamic> user;
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isGuess = false;

  @override
  void initState() {
    super.initState();
    // Seta se o usuário no momento já está logado
    FirebaseCrashlytics.instance.setCustomKey('guess', _isGuess);
    // Seta o id do usuário para melhoria na investigação
    FirebaseCrashlytics.instance.setUserIdentifier(widget.user['id']);
  }

  void crashApp() async {
    try {
      throw Error();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(
        {'action': 'cliquei propositalmente', 'description': 'test'},
        StackTrace.current,
        fatal: true,
        reason: 'Clicou propositalmente',
      );
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: crashApp,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
