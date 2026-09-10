import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StatusCompressorApp(),
  ));
}

class StatusCompressorApp extends StatefulWidget {
  const StatusCompressorApp({super.key});

  @override
  State<StatusCompressorApp> createState() => _StatusCompressorAppState();
}

class _StatusCompressorAppState extends State<StatusCompressorApp> {
  bool _isCompressing = false;
  String _statusText = "Prêt à compresser";

  Future<void> pickAndCompressVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    
    if (video == null) return;

    setState(() {
      _isCompressing = true;
      _statusText = "Compression en cours... Patientez.";
    });

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/status_hd_output.mp4';
      
      final File outputFile = File(outputPath);
      if (outputFile.existsSync()) {
        outputFile.deleteSync();
      }

      final String command = "-i '${video.path}' -c:v libx264 -preset ultrafast -crf 24 -vf scale=-2:1280 -r 30 -c:a aac -b:a 128k '$outputPath'";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await Gal.putVideo(outputPath);
        setState(() => _statusText = "Succès ! Vidéo HD sauvegardée dans la galerie.");
      } else {
        setState(() => _statusText = "Erreur lors de la compression.");
      }
    } catch (e) {
      setState(() => _statusText = "Erreur : $e");
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121B22),
      appBar: AppBar(
        title: const Text('Status HD Compressor'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (_isCompressing)
              const CircularProgressIndicator(color: Color(0xFF25D366))
            else
              ElevatedButton.icon(
                onPressed: pickAndCompressVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Choisir et Compresser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
