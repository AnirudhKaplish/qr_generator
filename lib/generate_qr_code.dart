import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrCode extends StatefulWidget {
  const GenerateQrCode({super.key});

  @override
  State<GenerateQrCode> createState() => _GenerateQrCodeState();
}

class _GenerateQrCodeState extends State<GenerateQrCode> {
  final TextEditingController urlController = TextEditingController();
  Color qrColor = Colors.black;
  Color bgColor = Colors.white;
  final GlobalKey qrKey = GlobalKey();

  Future<void> _saveQrCode() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    try {
      final boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 6.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "qr_code_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR code saved to gallery')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save QR code: $e')));
    }
  }

  void _pickColor({required bool isQRColor}) {
    Color tempColor = isQRColor ? qrColor : bgColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isQRColor ? 'Pick QR Code Color' : 'Pick Background Color'),
        content: ColorPicker(
          pickerColor: tempColor,
          onColorChanged: (color) => tempColor = color,
          enableAlpha: false,
          displayThumbColor: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (isQRColor) {
                  qrColor = tempColor;
                } else {
                  bgColor = tempColor;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTextAvailable = urlController.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3FF),
      body: Center(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          const Text(
            'QR Code Generator',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A11CB), // Match your theme
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Input Section
                  Container(
                    width: 600,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Color(0x99FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(blurRadius: 20, color: Colors.black12),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Your Content',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            hintText: 'Enter text, URL, or any data...',
                            filled: true,
                            fillColor: const Color(0xFFF4F4F4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildColorPreview(
                              'QR Color',
                              qrColor,
                              () => _pickColor(isQRColor: true),
                            ),
                            const SizedBox(width: 20),
                            _buildColorPreview(
                              'Background',
                              bgColor,
                              () => _pickColor(isQRColor: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _saveQrCode,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Download QR as Image',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Preview Section
                  Container(
                    width: 400,
                    height: 400,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(blurRadius: 20, color: Colors.black12),
                      ],
                    ),
                    child: Center(
                      child: isTextAvailable
                          ? RepaintBoundary(
                              key: qrKey,
                              child: QrImageView(
                                data: urlController.text.trim(),
                                size: 260,
                                backgroundColor: bgColor,
                                gapless: false,
                                dataModuleStyle: QrDataModuleStyle(
                                  color: qrColor,
                                  dataModuleShape: QrDataModuleShape.square,
                                ),
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: qrColor,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.palette,
                                  size: 60,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Enter Text Above',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Your QR code will appear here in real-time',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ],
      ),
      )
    );
  }

  Widget _buildColorPreview(String label, Color color, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text("#${color.value.toRadixString(16).substring(2)}"),
      ],
    );
  }
}
