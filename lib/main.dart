import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:ocr_text/img_to_txt.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageToTextAllLanguages(),
    );
  }
}

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _image;
  String scannedText = '';
  bool loading = false;
  final picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (file != null) {
      setState(() {
        _image = File(file.path);
        scannedText = '';
      });
      await scanText(file.path);
    }
  }

  Future<void> scanText(String imagePath) async {
    setState(() => loading = true);

    try {
      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'eng+guj+hin',
      );

      setState(() {
        scannedText =
        text.isEmpty ? 'No text detected' : text;
        loading = false;
      });
    } catch (e) {
      setState(() {
        scannedText = 'OCR Error: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline OCR (Stable)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 220),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : SelectableText(
              scannedText,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
