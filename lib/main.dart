import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(
      MyApp(),
    );

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File pickedImage;
  String data = '';

  bool isImageLoaded = false;

  Future pickImage() async {
    File tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (tempStore != null) {
      setState(() {
        pickedImage = tempStore;
        isImageLoaded = true;
      });
    }
  }

  Future<void> readText(BuildContext context) async {
    TextRecognizer textRecognizer;
    try {
      final FirebaseVisionImage ourImage =
          FirebaseVisionImage.fromFile(pickedImage);
      textRecognizer = FirebaseVision.instance.textRecognizer();
      final VisionText readText = await textRecognizer.processImage(ourImage);
      String _data = '';
      for (TextBlock block in readText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement word in line.elements) {
            print(word.text);
            _data = _data + ' ' + word.text;
          }
        }
      }
      setState(() {
        data = _data;
      });
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 500),
          content: Text('Click on Text to Copy'),
        ),
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        // barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Error',
            style: Theme.of(context).textTheme.headline,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 12,
              ),
              Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.body1,
              ),
            ],
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      );
    } finally {
      textRecognizer.close();
    }
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/background.png'),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 40,
                  ),
                  isImageLoaded
                      ? Center(
                          child: Container(
                            height: 200.0,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(pickedImage),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      : Placeholder(
                          fallbackHeight: 150,
                          fallbackWidth: 100,
                        ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    width: 150,
                    child: MaterialButton(
                      color: Colors.teal,
                      child: Text(
                        'Pick an image',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: pickImage,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Builder(
                    builder: (context) => SizedBox(
                      width: 150,
                      child: MaterialButton(
                        color: Colors.teal,
                        child: Text(
                          'Read Text',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          if (pickedImage == null) {
                            Scaffold.of(context).showSnackBar(
                              SnackBar(
                                duration: Duration(milliseconds: 500),
                                content: Text('First Select the Image'),
                              ),
                            );
                            return;
                          }
                          await readText(context);
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  isImageLoaded
                      ? Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Builder(
                              builder: (context) => SelectableText(
                                '$data',
                                style: Theme.of(context).textTheme.display1,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: data));
                                  HapticFeedback.heavyImpact();
                                  Scaffold.of(context).showSnackBar(
                                    SnackBar(
                                      duration: Duration(milliseconds: 1000),
                                      content: Text('Copied to ClipBoard'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      : Container(
                          child: Text(
                            'Pic an Image to extract Text',
                            style: Theme.of(context).textTheme.headline,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
