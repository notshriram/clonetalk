import 'dart:convert';

import 'package:audio_session/audio_session.dart';
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

typedef _Fn = void Function();

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  bool _audioExists = false;
  late Uri _uri;
  Uri? _fileLocation;
  bool _mPlayerIsInited = false;

  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();

  Future<Uri> getUserAudio() async {
    //get current user ID
    final FirebaseAuth _auth = FirebaseAuth.instance;
    //get auth user id
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(userId);
      //get the file
      final url = await ref.getDownloadURL();
      setState(() {
        _audioExists = true;
      });
      // ignore: avoid_print
      print(url);
      return Uri.parse(url);
    } catch (e) {
      setState(() {
        _audioExists = false;
      });
      // ignore: avoid_print
      print("error downloading audio" + e.toString());
      rethrow;
    }
  }

  //get storage permission
  void getPermission() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  @override
  void initState() {
    getUserAudio().then((value) => {
          setState(() {
            _uri = value;
            _audioExists = true;
          })
        });

    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    getPermission();

    super.initState();
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
  Future<void> generateAudio() async {
    //get firebase auth token
    final FirebaseAuth _auth = FirebaseAuth.instance;
    //get auth token
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken();

    // token works
    //ignore: avoid_print
    print(token);
    //accept aac audio
    Map<String, String> body = {
      "text": "hello world",
      "accept": "audio/X-HX-AAC-ADTS"
    };

    // Dio dio = Dio();
    // var data = FormData.fromMap(body);
    // dio.options.headers['content-Type'] = 'application/json';
    // dio.options.headers["authorization"] = token;
    // dio.options.headers["accept"] = 'audio/X-HX-AAC-ADTS';

    var headers = {
      "authorization": token,
      "accept": "audio/X-HX-AAC-ADTS",
    };

    try {
      final response = await http.post(
          Uri.parse("http://192.168.0.105:5000/api/generate"),
          headers: headers,
          body: body);
      // //ignore: avoid_print
      // print(response.data.toString());

      //get datetime
      final date = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');

      //response as audio file wav
      Directory? tempDir = await getStorageDirectory();
      String tempPath = tempDir!.path;
      //save file with datetime
      final savePath = '$tempPath/' + formatter.format(date) + '.aac';
      //ignore: avoid_print
      print(response.headers);
      File file = File(savePath);

      //save file
      file.writeAsBytesSync(response.bodyBytes);

      setState(() {
        _fileLocation = Uri.file(savePath);
      });
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
    if (!_mPlayerIsInited || !_audioExists) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  void play() {
    assert(_mPlayerIsInited && _audioExists);
    // ignore: avoid_print
    //print(_uri);
    _mPlayer!
        .startPlayer(
            fromURI: _fileLocation.toString(),
            codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
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

  _Fn? getGenerateFn() {
    if (_audioExists) {
      return generateAudio;
    }
    return null;
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
            Container(
              padding: const EdgeInsets.all(10),
              // if audio sample exists, show form else show text
              child: _audioExists
                  ? Column(children: const [
                      Text(
                        'Title',
                        style: TextStyle(fontSize: 20),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Text(
                        'Narration Text',
                        style: TextStyle(fontSize: 20),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ])
                  : const Text(
                      'Audio Sample Does not exist. Please navigate to your profile and upload your voice sample.'),
            ),
            ElevatedButton(
              child: const Text("Generate"),
              onPressed: getGenerateFn(),
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
