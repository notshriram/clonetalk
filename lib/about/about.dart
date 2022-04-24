import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  void _launchUrl(url) async {
    if (!await launchUrl(url)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    // return a Scaffold with an appbar
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: 'Clone',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: Colors.indigo)),
              TextSpan(
                  text: 'talk.',
                  style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber)),
            ])),
            const Text('An app for voice cloning and text narration'),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                          text:
                              "CloneTalk is a voice-based narration app that allows you to clone a voice and use it to narrate any arbitrary text. It's a great way to create audio recordings of text material and to emulate conversations for video planning and production. This app is based on the work of Corentin Jemine and his master thesis at the University of Applied Sciences in Liege, Belgium. "),
                      TextSpan(
                        text: 'Link to the thesis',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(Uri.parse(
                                "https://matheo.uliege.be/handle/2268.2/6801"));
                          },
                      ),
                    ],
                  ),
                )),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                          text:
                              "This app is free and open-source. You can find the source code on GitHub. You may also submit your issues/ feedback/ Contributions on the GitHub page. "),
                      TextSpan(
                        text: 'Link to Github Repository',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(Uri.parse(
                                "https://github.com/notshriram/clonetalk"));
                          },
                      ),
                    ],
                  ),
                )),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Made with ❤️ by:',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.normal),
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        'Students of B. V. Raju Institute of Technology viz. Shriram, Suhruth, Janakiram and Prof. U Gnaneshwara Chary',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w300),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
