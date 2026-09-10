import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  String? _outputPath;

  Future<void> pickAndCompressVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    setState(() {
      _isCompressing = true;
      _outputPath = null;
      _statusText = "Compression en cours... Patientez.";
    });

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/status_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Le filtre scale ci-dessous s'adapte automatiquement à l'orientation :
      // - vidéo portrait  -> hauteur bloquée à 1280, largeur calculée
      // - vidéo paysage   -> largeur bloquée à 1280, hauteur calculée
      // Les guillemets simples protègent les virgules internes de l'expression
      // "if(...)" pour que le parseur de filtres de FFmpeg ne les confonde pas
      // avec un séparateur de filtres.
      final String command =
          "-i '${video.path}' -c:v libx264 -preset medium -crf 20 -maxrate 3M -bufsize 6M -vf \"scale='if(gt(iw,ih),1280,-2)':'if(gt(iw,ih),-2,1280)'\" -r 30 -c:a aac -b:a 128k -y '$outputPath'";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputPath;
          _statusText = "Succès ! Vidéo compressée, prête à partager.";
        });
      } else {
        setState(() => _statusText = "Erreur lors de la compression.");
      }
    } catch (e) {
      setState(() => _statusText = "Erreur : $e");
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  Future<void> shareVideo() async {
    if (_outputPath == null) return;
    await Share.shareXFiles(
      [XFile(_outputPath!)],
      text: 'Statut WhatsApp compressé',
    );
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_isCompressing)
                const CircularProgressIndicator(color: Color(0xFF25D366))
              else ...[
                ElevatedButton.icon(
                  onPressed: pickAndCompressVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Choisir et Compresser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (_outputPath != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: shareVideo,
                    icon: const Icon(Icons.share),
                    label: const Text('Partager sur WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
