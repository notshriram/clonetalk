import 'package:clonetalk/shared/bottom_nav.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

typedef _Fn = void Function();

class HomeWidget extends StatelessWidget {
  const HomeWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyAudioList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new');
        },
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class MyAudioList extends StatefulWidget {
  const MyAudioList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAudioList(); //create state
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

class _MyAudioList extends State<MyAudioList> {
  late List<FileSystemEntity> files;
  bool _mPlayerIsInited = false;
  final FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  String? _fileLocation;
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

  Future<void> getFiles() async {
    Directory? dir = await getStorageDirectory();
    String mp3Path = dir.toString();
    print(mp3Path);
    List<FileSystemEntity> _files;
    List<FileSystemEntity> _songs = [];
    _files = dir!.listSync(recursive: true, followLinks: false);
    for (FileSystemEntity entity in _files) {
      String path = entity.path;
      if (path.endsWith('.wav')) _songs.add(entity);
    }
    setState(() {
      files = _songs;
    });
    // ignore: avoid_print
    print(_songs);
    // ignore: avoid_print
    print('Length of list $_songs.length');
    setState(() {}); //update the UI
  }

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    getFiles(); //call getFiles() function on initial state.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("Audio File list from Storage"),
            backgroundColor: Colors.redAccent),
        body: files.isEmpty
            ? const Text("Searching Files")
            : ListView.builder(
                //if file/folder list is grabbed, then show here
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return Card(
                      child: ListTile(
                    title: Text(
                        files[index].path.split('/').last.split('.').first),
                    leading: const Icon(Icons.audiotrack),
                    trailing: const Icon(
                      Icons.play_arrow,
                      color: Colors.redAccent,
                    ),
                    onTap: () => {
                      setState(() {
                        _fileLocation = files[index].path;
                      }),
                      getPlaybackFn()?.call()
                    },
                  ));
                },
              ));
  }
}
