import 'package:flutter/material.dart';
import 'dart:async';
import 'package:background_downloader/background_downloader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int segmentsCounter = 0;
  int totalSegments = 143;
  TaskStatus? downloadTaskStatus;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();

    FileDownloader().configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 100)),
    ], androidConfig: [
      (Config.useCacheDir, Config.whenAble),
    ], iOSConfig: [
      (Config.localize, {'Cancel': 'StopIt'}),
    ]).then((result) => debugPrint('Configuration result = $result'));

    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        if (update.status == TaskStatus.complete){
          segmentsCounter++;
          if (segmentsCounter >= totalSegments){
            debugPrint('*** Download completed');
          }
        }
        setState(() {
          downloadTaskStatus = update.status; // update screen
        });
      } else if (update is TaskProgressUpdate) {
        debugPrint('***** Progress update for ${update.task} with progress ${update.progress}');
      }

    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(
              height: 30,
              thickness: 5,
              color: Colors.grey,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('File downloaded $totalSegments : $segmentsCounter'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton.icon (
              icon: const Icon(Icons.play_arrow, color: Colors.red),
              label: const Text('Start'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey,
                shadowColor: Colors.black,
                elevation: 3.0,
              ),
              onPressed: () {
                addTasks();
                setState(() {
                  segmentsCounter = 1;
                });
              },
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> addTasks () async {
    for (int i=1; i<totalSegments; i++) {
      await addTask(groupid: 'groupid', fileName: i.toString());
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> addTask ({required groupid, required String fileName}) async {
    String _baseUri = 'https://europe.olemovienews.com/hlstimeofffmp4/20190930/quzhlBxH/mp4/quzhlBxH.mp4/';
    String url = '${_baseUri}seg-${fileName}-v1-a1.m4s';
    debugPrint('Download Url : $fileName , $url');
    var tsk = DownloadTask(
      url: url,
      group: groupid,
      filename: fileName,
      updates: Updates.status,
      directory: groupid,
      baseDirectory: BaseDirectory.applicationDocuments,
      retries: 3,
      allowPause: true,
    );
    await FileDownloader().enqueue(tsk); // must provide progress updates!
  }
}
