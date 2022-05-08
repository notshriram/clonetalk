/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart';

import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
//import firebase storage
import 'package:firebase_storage/firebase_storage.dart';
/*
 * This is an example showing how to record to a Dart Stream.
 * It writes all the recorded data from a Stream to a File, which is completely stupid:
 * if an App wants to record something to a File, it must not use Streams.
 *
 * The real interest of recording to a Stream is for example to feed a
 * Speech-to-Text engine, or for processing the Live data in Dart in real time.
 *
 */

///
typedef _Fn = void Function();

/* This does not work. on Android we must have the Manifest.permission.CAPTURE_AUDIO_OUTPUT permission.
 * But this permission is _is reserved for use by system components and is not available to third-party applications._
 * Pleaser look to [this](https://developer.android.com/reference/android/media/MediaRecorder.AudioSource#VOICE_UPLINK)
 *
 * I think that the problem is because it is illegal to record a communication in many countries.
 * Probably this stands also on iOS.
 * Actually I am unable to record DOWNLINK on my Xiaomi Chinese phone.
 *
 */
//const theSource = AudioSource.voiceUpLink;
//const theSource = AudioSource.voiceDownlink;

const theSource = AudioSource.microphone;

/// Example app.
class SimpleRecorder extends StatefulWidget {
  const SimpleRecorder({Key? key, required this.setThreadId}) : super(key: key);

  final void Function(String) setThreadId;

  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

Future<Directory?> getStorageDirectory() async {
  if (Platform.isAndroid) {
    return (await getExternalStorageDirectory());
    // OR return "/storage/emulated/0/Download";
  } else {
    return (await getApplicationDocumentsDirectory());
  }
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Codec _codec = Codec.aacADTS;
  //response as audio file wav

  String _mPath = 'tau_file.aac';
  late String? url;
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String _timerText = '00:00:00';

  bool _uploadReady = false;
  bool _uploading = false;
  bool _uploaded = false;

  void initializer() async {
    await Permission.microphone.request();
  }

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();
    initializer();
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  // ----------------------  Here is the code for recording and playback -------

  void record() {
    _mRecorder!
        .startRecorder(
      codec: _codec,
      toFile: _mPath,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
    StreamSubscription _recorderSubscription =
        _mRecorder!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds,
          isUtc: true);
      var timeText = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _timerText = timeText.substring(0, 8);
      });
    });
    _recorderSubscription.cancel();
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        url = value;
        _mplaybackReady = true;
        _uploadReady = true;
      });
    });
  }

  void play() {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
            fromURI: url,
            codec: kIsWeb ? Codec.opusWebM : _codec,
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

  Future<String?> uploadToAPI() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    setState(() {
      _uploading = true;
      _uploadReady = false;
    });
    //get the audio file
    final file = (File(url!));

    //get auth user id
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken();

    // final streamedRequest = http.StreamedRequest(
    //     'POST', Uri.parse('http://192.168.0.108:8888/generate'))
    //   ..headers.addAll({
    //     'Cache-Control': 'no-cache',
    //     'authorization': token,
    //     'content-type': 'audio/X-HX-AAC-ADTS'
    //   });
    // streamedRequest.contentLength = await file.length();
    // file.openRead().listen((chunk) {
    //   // ignore: avoid_print
    //   print(chunk.length);
    //   streamedRequest.sink.add(chunk);
    // }, onDone: () {
    //   streamedRequest.sink.close();
    // });

    //final response = await streamedRequest.send();

    //send audio file to api

    var request = http.MultipartRequest(
        "POST", Uri.parse('http://192.168.0.108:8888/generate'));
    request.fields['authorization'] = token;
    request.fields['text'] = 'test';
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('audio', 'X-HX-AAC-ADTS'),
    ));
    request.send().then((response) {
      // ignore: avoid_print

      if (response.statusCode == 200) {
        response.stream.listen((value) {
          //decode utf-8
          var decoder = const Utf8Decoder();
          var result = decoder.convert(value);

          widget.setThreadId(result);

          setState(() {
            _uploaded = true;
            _uploading = false;
          });

          //ignore: avoid_print
          print(result);
        });
      }
    });
    return null;
  }

  Future<Uri?> uploadAudioFirebase() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    //get the audio file
    final file = File(url!);

    //get auth user id
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;

    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(userId);
      UploadTask uploadTask = ref.putFile(file);
      uploadTask.then((res) {
        return res.ref.getDownloadURL();
      });
    } catch (e) {
      // ignore: avoid_print
      print("error uploading audio" + e.toString());
    }
    return null;
  }

// ----------------------------- UI --------------------------------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  _Fn? getUploadFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? uploadToAPI : stopPlayer;
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.purple[300],
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getRecorderFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mRecorder!.isRecording
                  ? 'Recording in progress'
                  : 'Recorder is stopped'),
            ]),
          ),
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.pink[400],
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getPlaybackFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer!.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
          ),
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green[400],
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getUploadFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: const Text('Upload'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_uploadReady
                  ? 'Ready To Upload'
                  : _uploading
                      ? 'Uploading...'
                      : _uploaded
                          ? 'Uploaded'
                          : 'Not Ready'),
            ]),
          ),
        ],
      );
    }

    return Container(
      child: makeBody(),
    );
  }
}
