import 'dart:convert';
import 'dart:ffi';

import 'package:audio_session/audio_session.dart';
import 'package:clonetalk/profile/recorder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
//import firebase storage
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

typedef _Fn = void Function();

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _audioExists = false;
  bool _downloadable = false;
  late Uri _uri;
  Uri? _fileLocation;
  bool _mPlayerIsInited = false;
  double progress = 0;
  String? _threadId;
  bool _generating = false;

  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();

  //get storage permission
  void getPermission() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    getPermission();

    super.initState();
  }

  Future<void> queryProgress() async {
    var progressRequest = http.Request(
        'GET', Uri.parse('http://192.168.0.108:8888/progress/$_threadId'));
    progressRequest.headers.addAll({'Accept': 'text/plain'});
    var response = await progressRequest.send();
    if (response.statusCode == 200) {
      response.stream.listen((value) {
        //decode utf-8
        var decoder = const Utf8Decoder();
        var result = decoder.convert(value);
        setState(() {
          progress = double.parse(result);
        });
      });
    }
  }

  Future<Directory?> getStorageDirectory() async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectory());
      // OR return "/storage/emulated/0/Download";
    } else {
      return (await getApplicationDocumentsDirectory());
    }
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      //ignore: avoid_print
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  //generate audio from server using POST Request
  Future<void> getGeneratedAudio() async {
    //get firebase auth token
    final FirebaseAuth _auth = FirebaseAuth.instance;
    //get auth token
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken();

    // token works
    //ignore: avoid_print
    print(token);

    // Dio dio = Dio();
    // var data = FormData.fromMap(body);
    // dio.options.headers['content-Type'] = 'application/json';
    // dio.options.headers["authorization"] = token;
    // dio.options.headers["accept"] = 'audio/X-HX-AAC-ADTS';

    var headers = {
      "authorization": token,
      "accept": "audio/x-wav",
    };

    try {
      final response = await http.get(
          Uri.parse("http://192.168.0.108:8888/download/$_threadId"),
          headers: headers);
      // //ignore: avoid_print
      // print(response.data.toString());

      //get datetime
      final date = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');

      //response as audio file wav
      Directory? tempDir = await getStorageDirectory();
      String tempPath = tempDir!.path;
      //save file with datetime
      final savePath = '$tempPath/' + formatter.format(date) + '.wav';
      //ignore: avoid_print
      print(response.headers);
      File file = File(savePath);

      //download the file from response
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _fileLocation = Uri.file(savePath);
      });
      print('File locn downloaded $_fileLocation');
      return;
    } catch (e) {
      //ignore: avoid_print
      print(e);
      rethrow;
    }
  }

  _Fn? getPlaybackFn() {
    //ignore: avoid_print
    //print(_uri);
    if (!_mPlayerIsInited || _fileLocation == null) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  void play() {
    assert(_mPlayerIsInited && _fileLocation != null);
    // ignore: avoid_print
    //print(_uri);
    _mPlayer!
        .startPlayer(
            fromURI: _fileLocation.toString(),
            codec: kIsWeb ? Codec.opusWebM : Codec.pcm16WAV,
            whenFinished: () {
              setState(() {});
            })
        .then((value) {
      setState(() {});
    });
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

  void cancel() {
    //cancel generating
    setState(() {
      _generating = false;
    });
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;
    super.dispose();
  }

  void createNewNarration() {
    //ignore: avoid_print
    print("create new narration");
  }

  _Fn? getAudioFn() {
    if (_audioExists) {
      return createNewNarration;
    }
    return null;
  }

  _Fn? getDownloadFn() {
    if (_downloadable) {
      return getGeneratedAudio;
    }
    return null;
  }

  void setThreadId(String threadId) {
    //ignore: avoid_print
    print('Setting Thread Id $threadId');
    setState(() {
      _threadId = threadId;
    });
    Timer timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      queryProgress();
      if (progress >= 98) {
        timer.cancel();
        setState(() {
          progress = 100;
          _downloadable = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Narration'),
      ),
      body: Center(
        child: Column(
          children: [
            SimpleRecorder(
              setThreadId: setThreadId,
            ),
            Form(
              key: _formKey,
              child: Column(children: [
                const Text(
                  'Title',
                  style: TextStyle(fontSize: 20),
                ),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const Text(
                  'Narration Text',
                  style: TextStyle(fontSize: 20),
                ),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),
            ),
            _threadId != null
                ? Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.all(10),
                    child: LiquidLinearProgressIndicator(
                      value: progress / 100, // Defaults to 0.5.
                      borderColor: Colors.red,
                      borderWidth: 0.0,
                      borderRadius:
                          12.0, // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.horizontal.
                      center: Text("generating..."),
                    ),
                  )
                : Container(),
            ElevatedButton(
              child: const Text("download"),
              onPressed: getDownloadFn(),
            ),
            ElevatedButton(
              child: const Text("Play"),
              onPressed: getPlaybackFn(),
            ),
          ],
        ),
      ),
    );
  }
}
