import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';

enum Algorithm {
  sha1,
  sha224,
  sha256,
  sha384,
  sha512,
  sha512224,
  sha512256,
  md5,
}

enum ApplicationState {
  notReady,
  processing,
  ok,
  error,
}

void main(List<String> args) {
  runApp(const FilePickerApp());
}

class CalcHashData {
  CalcHashData(this.bin, this.algorithm);

  Uint8List bin;
  Algorithm algorithm;
}

class FilePickerApp extends StatelessWidget {
  const FilePickerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appName = 'CheckSumChecker';
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
        ),
      ),
      home: const FilePickerWidget(title: appName),
    );
  }
}

class FilePickerWidget extends StatefulWidget {
  const FilePickerWidget({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  var _algorithm = Algorithm.sha256;
  var _appState = ApplicationState.notReady;
  var _infolText = 'Please choose your file.';
  var _hashValue = '';
  final _textEditController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _textEditController.dispose();
  }

  static Future<String> _calcHash(CalcHashData input) {
    Digest dig;
    switch (input.algorithm) {
      case Algorithm.sha1:
        dig = sha1.convert(input.bin);
        break;
      case Algorithm.sha224:
        dig = sha224.convert(input.bin);
        break;
      case Algorithm.sha256:
        dig = sha256.convert(input.bin);
        break;
      case Algorithm.sha384:
        dig = sha384.convert(input.bin);
        break;
      case Algorithm.sha512:
        dig = sha512.convert(input.bin);
        break;
      case Algorithm.sha512224:
        dig = sha512224.convert(input.bin);
        break;
      case Algorithm.sha512256:
        dig = sha512256.convert(input.bin);
        break;
      case Algorithm.md5:
        dig = md5.convert(input.bin);
        break;
    }
    return Future<String>.value('$dig');
  }

  Future<void> _pickFile() async {
    var result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) {
      setState(() {
        _appState = ApplicationState.notReady;
        _infolText = 'Please choose your file.';
      });
      return;
    }

    PlatformFile file;
    try {
      file = result.files.single;
    } catch (e) {
      setState(() {
        _appState = ApplicationState.error;
        _infolText = 'Sorry, but an error occured. Could not open a file';
      });
      return;
    }

    var bin = file.bytes;
    if (bin == null) {
      setState(() {
        _appState = ApplicationState.error;
        _infolText = 'Sorry, but an error occured. Could not read a file.';
      });
      return;
    }

    var fileName = file.name;
    _hashValue = await compute(_calcHash, CalcHashData(bin, _algorithm));
    setState(() {
      _appState = ApplicationState.notReady;
      _infolText = "FileName: $fileName\n\nHash: $_hashValue";
    });
  }

  void _checkEquality(String input) {
    if (_hashValue.isEmpty) {
      setState(() {
        _appState = ApplicationState.notReady;
        _infolText = 'Please select a file.';
      });
      return;
    } else if (input.isEmpty) {
      setState(() {
        _appState = ApplicationState.notReady;
        _infolText = 'Please enter provided checksum.';
      });
      return;
    }

    if (input.compareTo(_hashValue) == 0) {
      setState(() {
        _appState = ApplicationState.ok;
        _infolText = 'OK !!';
      });
    } else {
      setState(() {
        _appState = ApplicationState.error;
        _infolText = 'Checksum is not same.';
      });
    }
  }

  ChoiceChip _makeChiceChip(String label, Algorithm algorithm) {
    return ChoiceChip(
      selectedColor: Colors.blue,
      label: Text(label),
      selected: _algorithm == algorithm,
      onSelected: (value) {
        setState(() {
          _algorithm = algorithm;
        });
      },
    );
  }

  Widget _makeIndicator(ApplicationState appState) {
    switch (appState) {
      case ApplicationState.notReady:
        return const Icon(
          Icons.info,
          color: Colors.blue,
          size: 80,
        );
      case ApplicationState.processing:
        return const CircularProgressIndicator();
      case ApplicationState.ok:
        return const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        );
      case ApplicationState.error:
        return const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 80,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    var algorithmUnit = SizedBox(
      height: 80.0,
      child: Column(
        children: [
          const SizedBox(height: 40.0),
          Wrap(
            children: [
              _makeChiceChip('sha1', Algorithm.sha1),
              const SizedBox(width: 15),
              _makeChiceChip('sha224', Algorithm.sha224),
              const SizedBox(width: 15),
              _makeChiceChip('sha256', Algorithm.sha256),
              const SizedBox(width: 15),
              _makeChiceChip('sha384', Algorithm.sha384),
              const SizedBox(width: 15),
              _makeChiceChip('sha512', Algorithm.sha512),
              const SizedBox(width: 15),
              _makeChiceChip('sha512/224', Algorithm.sha512224),
              const SizedBox(width: 15),
              _makeChiceChip('sha512/256', Algorithm.sha512256),
              const SizedBox(width: 15),
              _makeChiceChip('md5', Algorithm.md5),
            ],
          ),
        ],
      ),
    );

    var indicatorUnit = Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 80,
            height: 80,
            child: _makeIndicator(_appState),
          ),
        )
      ],
    );

    var infoUnit = SizedBox(
      height: 160.0,
      child: Center(
        child: Text(
          _infolText,
          textScaleFactor: 1.2,
        ),
      ),
    );

    var buttonUnit = Center(
      child: ElevatedButton(
        onPressed: () {
          if (_appState == ApplicationState.processing) {
            return;
          }

          _pickFile();

          setState(() {
            _appState = ApplicationState.processing;
            _infolText = 'Please wait for a while...';
          });
        },
        child: const Text("Pick A File"),
      ),
    );

    var inputUnit = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          height: 100.0,
        ),
        SizedBox(
          width: 1150.0,
          height: 100.0,
          child: TextField(
            controller: _textEditController,
            onSubmitted: _checkEquality,
            decoration: const InputDecoration(
              hintText: 'Please enter provided checksum here',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _checkEquality(_textEditController.value.text);
          },
          child: const Text("Check equality"),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
          ],
        ),
      ),
      body: Center(
        child: ListView(
          children: [
            algorithmUnit,
            indicatorUnit,
            infoUnit,
            buttonUnit,
            inputUnit,
          ],
        ),
      ),
    );
  }
}
