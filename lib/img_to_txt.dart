import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageToTextAllLanguages extends StatefulWidget {
  const ImageToTextAllLanguages({super.key});

  @override
  State<ImageToTextAllLanguages> createState() =>
      _ImageToTextAllLanguagesState();
}

class _ImageToTextAllLanguagesState extends State<ImageToTextAllLanguages> {
  File? _imageFile;
  String extractedText = '';
  bool isLoading = false;

  // Default Language: English
  TextRecognitionScript _selectedScript = TextRecognitionScript.latin;

  final ImagePicker picker = ImagePicker();

  // Helper to get friendly names for the dropdown
  String _getScriptName(TextRecognitionScript script) {
    switch (script) {
      case TextRecognitionScript.latin:
        return 'English / Latin';
      case TextRecognitionScript.devanagiri:
        return 'Devanagari (Hindi/Marathi)';
      case TextRecognitionScript.chinese:
        return 'Chinese';
      case TextRecognitionScript.japanese:
        return 'Japanese';
      case TextRecognitionScript.korean:
        return 'Korean';
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        isLoading = true;
        _imageFile = File(image.path);
        extractedText = '';
      });

      final inputImage = InputImage.fromFilePath(image.path);

      // ✅ FIX: Use ONLY the selected script recognizer
      // This prevents the "garbage characters" and duplicates
      final recognizer = TextRecognizer(script: _selectedScript);

      try {
        final recognizedText = await recognizer.processImage(inputImage);

        // Simple text extraction preserving lines
        // We do NOT use a loop over all scripts anymore.
        extractedText = recognizedText.text;

      } finally {
        recognizer.close();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        extractedText = "Error occurred: $e";
      });
    }
  }

  void _copyToClipboard() {
    if (extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard!')),
      );
    }
  }

  void _clearAll() {
    setState(() {
      _imageFile = null;
      extractedText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- 1. Language Selector Dropdown ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TextRecognitionScript>(
                  isExpanded: true,
                  value: _selectedScript,
                  icon: const Icon(Icons.language, color: Colors.blue),
                  items: TextRecognitionScript.values.map((script) {
                    return DropdownMenuItem(
                      value: script,
                      child: Text(_getScriptName(script), style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedScript = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. Image Preview ---
            if (_imageFile != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Select an image to scan", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --- 3. Action Buttons ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // --- 4. Extracted Text Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Scanned Text",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: extractedText.isNotEmpty ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy, color: Colors.grey),
                  tooltip: "Copy",
                ),
              ],
            ),

            // --- 5. Result Display ---
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      extractedText.isEmpty
                          ? 'No text detected yet.'
                          : extractedText,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}