import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
//import firebase storage
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';

typedef _Fn = void Function();

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  bool _audioExists = false;
  late Uri _uri;
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
    super.initState();
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
    Map<String, String> body = {"text": "hello world", "accept": "audio/mp3"};

    Dio dio = Dio();
    var data = FormData.fromMap(body);
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] = token;
    final response =
        await dio.post("http://shrigmac.local:5000/api/generate", data: data);
    //ignore: avoid_print
    print(response.statusCode);
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_audioExists) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  void play() {
    assert(_mPlayerIsInited && _audioExists);
    _mPlayer!
        .startPlayer(
            fromURI: _uri.toString(),
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
              child: const Text("Play Sample"),
              onPressed: getPlaybackFn(),
            ),
            ElevatedButton(
              child: const Text("Token"),
              onPressed: () => generateAudio(),
            ),
          ],
        ),
      ),
    );
  }
}
