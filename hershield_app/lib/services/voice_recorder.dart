import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

/// Records the microphone to a WAV file held in memory. Works on web and
/// Android. Nothing is written to disk.
class VoiceRecorder {
  static const sampleRate = 16000;
  static const maxSeconds = 180; // 3 minutes ≈ 5.8 MB

  final AudioRecorder _rec = AudioRecorder();
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _sub;

  /// Returns false if the microphone permission was not granted.
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    _pcm.clear();
    final stream = await _rec.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
    ));
    _sub = stream.listen(_pcm.add);
    return true;
  }

  /// Stops recording and returns the WAV bytes (or null if empty).
  Future<Uint8List?> stop() async {
    await _rec.stop();
    await _sub?.cancel();
    _sub = null;
    final pcm = _pcm.takeBytes();
    if (pcm.isEmpty) return null;
    return _wav(pcm);
  }

  Future<void> cancel() async {
    await _sub?.cancel();
    _sub = null;
    _pcm.clear();
    await _rec.cancel();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _rec.dispose();
  }

  static Uint8List _wav(Uint8List pcm) {
    final h = ByteData(44);
    void tag(int o, String t) {
      for (var i = 0; i < 4; i++) {
        h.setUint8(o + i, t.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little); // PCM
    h.setUint16(22, 1, Endian.little); // mono
    h.setUint32(24, sampleRate, Endian.little);
    h.setUint32(28, sampleRate * 2, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);

    final out = Uint8List(44 + pcm.length);
    out.setRange(0, 44, h.buffer.asUint8List());
    out.setRange(44, out.length, pcm);
    return out;
  }
}
