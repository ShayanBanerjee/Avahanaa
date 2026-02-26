import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../utils/qr_payload_builder.dart';

class QRCodeScreen extends StatelessWidget {
  final UserModel user;
  final VehicleModel vehicle;

  const QRCodeScreen({super.key, required this.user, required this.vehicle});
  static const double _shareQrImageSize = 600;
  static const String _qrTemplateAsset = 'assets/images/qr_template.png';
  static const double _qrBoxWidthFactor = 0.42;
  static const double _qrBoxTopFactor = 0.115;
  static const double _qrBoxPaddingFactor = 0.06;
  static const double _qrBoxCornerRadiusFactor = 0.08;
  static final Future<ui.Image> _templateImageFuture = _loadTemplateImage();

  @override
  Widget build(BuildContext context) {
    final qrPayload = QrPayloadBuilder.buildPayload(
      user: user,
      vehicle: vehicle,
    );
    final shareableLink = QrPayloadBuilder.buildShareableLink(
      user: user,
      vehicle: vehicle,
    );
    final licensePlate = vehicle.licensePlate;
    final carDescriptor = [
      vehicle.color,
      vehicle.carModel,
    ].where((part) => part.isNotEmpty).join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareQRCode(context, qrPayload),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: const Color(0xFFF0F9FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Print this QR code and place it on your car windshield',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // QR Code
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildQrPreview(qrPayload),
                    if (licensePlate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        licensePlate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                    if (carDescriptor.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        carDescriptor,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(context, shareableLink),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy QR Link'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQRCode(context, qrPayload),
                      icon: const Icon(Icons.share),
                      label: const Text('Share QR Code'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Instructions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Printing Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInstruction('1', 'Screenshot this QR code'),
                      _buildInstruction(
                        '2',
                        'Print it on white paper (A5 size recommended)',
                      ),
                      _buildInstruction(
                        '3',
                        'Laminate or use a clear plastic sleeve',
                      ),
                      _buildInstruction(
                        '4',
                        'Place on your car windshield (inside)',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<ui.Image> _loadTemplateImage() async {
    final data = await rootBundle.load(_qrTemplateAsset);
    final bytes = data.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Widget _buildQrPreview(String qrData) {
    return FutureBuilder<ui.Image>(
      future: _templateImageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              _buildTemplateQr(qrData, snapshot.data!),
              const SizedBox(height: 12),
            ],
          );
        }
        return _buildClassicQr(qrData);
      },
    );
  }

  Widget _buildClassicQr(String qrData) {
    return Column(
      children: [
        QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 280,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.L,
          gapless: true,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: const Color(0xFF2563EB),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '🚗 Avahanaa',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan to notify owner',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTemplateQr(String qrData, ui.Image templateImage) {
    final aspectRatio = templateImage.width / templateImage.height;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final qrBoxSize = width * _qrBoxWidthFactor;
          final qrBoxTop = height * _qrBoxTopFactor;
          final qrBoxLeft = (width - qrBoxSize - 5) / 2;
          final qrBoxPadding = qrBoxSize * _qrBoxPaddingFactor;
          final qrRadius = qrBoxSize * _qrBoxCornerRadiusFactor;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(_qrTemplateAsset, fit: BoxFit.cover),
              ),
              Positioned(
                left: qrBoxLeft,
                top: qrBoxTop,
                width: qrBoxSize,
                height: qrBoxSize,
                child: Container(
                  padding: EdgeInsets.all(qrBoxPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(qrRadius),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.L,
                    gapless: true,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: const Color(0xFF2563EB),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareQRCode(BuildContext context, String qrData) async {
    try {
      final pngBytes = await _buildQrPngBytes(qrData, _shareQrImageSize);
      if (pngBytes == null) {
        _showShareError(context);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/avahanaa-qr-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Scan my Avahanaa QR code to notify me.',
        subject: 'My Avahanaa QR Code',
      );
    } catch (_) {
      _showShareError(context);
    }
  }

  Future<List<int>?> _buildQrPngBytes(String data, double size) async {
    final templateImage = await _loadTemplateImageSafely();
    if (templateImage != null) {
      return _buildTemplateQrBytes(data, templateImage);
    }

    return _buildPlainQrBytes(data, size);
  }

  Future<ui.Image?> _loadTemplateImageSafely() async {
    try {
      return await _templateImageFuture;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>?> _buildPlainQrBytes(String data, double size) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: const Color(0xFF2563EB),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black87,
      ),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
    painter.paint(canvas, Size(size, size));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<List<int>?> _buildTemplateQrBytes(
    String data,
    ui.Image templateImage,
  ) async {
    final width = templateImage.width.toDouble();
    final height = templateImage.height.toDouble();
    final qrBoxSize = width * _qrBoxWidthFactor;
    final qrBoxTop = height * _qrBoxTopFactor;
    final qrBoxLeft = (width - qrBoxSize) / 2;
    final qrBoxPadding = qrBoxSize * _qrBoxPaddingFactor;
    final qrRadius = qrBoxSize * _qrBoxCornerRadiusFactor;
    final qrSize = qrBoxSize - (qrBoxPadding * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    canvas.drawImage(templateImage, Offset.zero, Paint());

    final boxRect = Rect.fromLTWH(qrBoxLeft, qrBoxTop, qrBoxSize, qrBoxSize);
    final boxPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(qrRadius)),
      boxPaint,
    );

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
      gapless: true,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: const Color(0xFF2563EB),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black87,
      ),
    );

    canvas.save();
    canvas.translate(qrBoxLeft + qrBoxPadding, qrBoxTop + qrBoxPadding);
    painter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _showShareError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to share the QR code image.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
