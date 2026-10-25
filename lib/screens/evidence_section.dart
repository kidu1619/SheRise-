import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../services/voice_recorder.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const _maxItems = 5;
const _maxBytes = 10 * 1024 * 1024;
const _mimes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'pdf': 'application/pdf',
};

String _size(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).round()} KB';

String _clock(int s) =>
    '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Photo / PDF upload and voice-note recording for a report.
class EvidenceSection extends ConsumerStatefulWidget {
  const EvidenceSection({super.key});

  @override
  ConsumerState<EvidenceSection> createState() => _EvidenceSectionState();
}

class _EvidenceSectionState extends ConsumerState<EvidenceSection> {
  final _voice = VoiceRecorder();
  Timer? _timer;
  bool _recording = false;
  int _seconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _voice.dispose();
    super.dispose();
  }

  void _add(Attachment a) => ref
      .read(draftProvider.notifier)
      .patch((d) => d.copyWith(attachments: [...d.attachments, a]));

  void _removeAt(int i) =>
      ref.read(draftProvider.notifier).patch((d) {
        final list = [...d.attachments]..removeAt(i);
        return d.copyWith(attachments: list);
      });

  bool get _full => ref.read(draftProvider).attachments.length >= _maxItems;

  Future<void> _pickFile() async {
    if (_full) {
      snack(context, 'You can attach up to 5 items.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _mimes.keys.toList(),
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        if (mounted) snack(context, 'Could not read that file.');
        return;
      }
      if (bytes.length > _maxBytes) {
        if (mounted) snack(context, 'That file is larger than 10 MB.');
        return;
      }
      final ext = (f.extension ?? '').toLowerCase();
      final mime = _mimes[ext];
      if (mime == null) {
        if (mounted) snack(context, 'Only JPG, PNG and PDF files are allowed.');
        return;
      }
      _add(Attachment(
          name: f.name, kind: 'file', ext: ext, mime: mime, bytes: bytes));
    } catch (_) {
      if (mounted) snack(context, 'Could not open the file picker.');
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await _stopRecording();
      return;
    }
    if (_full) {
      snack(context, 'You can attach up to 5 items.');
      return;
    }
    try {
      final ok = await _voice.start();
      if (!ok) {
        if (mounted) {
          snack(context, 'Microphone permission is needed to record a voice note.');
        }
        return;
      }
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= VoiceRecorder.maxSeconds) _stopRecording();
      });
    } catch (_) {
      if (mounted) snack(context, 'Could not start recording.');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final seconds = _seconds;
    final bytes = await _voice.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    if (bytes == null) {
      snack(context, 'Nothing was recorded.');
      return;
    }
    _add(Attachment(
      name: 'Voice note',
      kind: 'voice',
      ext: 'wav',
      mime: 'audio/wav',
      bytes: bytes,
      seconds: seconds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(draftProvider).attachments;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Tx('Evidence (optional)',
          style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Tx(
          'Add up to 5 items: photos, PDFs or a voice note. Each up to 10 MB.',
          style: TextStyle(fontSize: 12, color: C.muted)),
      const SizedBox(height: 10),
      SecondaryButton(
          label: 'Add a photo or PDF',
          icon: Icons.attach_file,
          onPressed: _recording ? null : _pickFile),
      const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Tx('You can speak instead of typing',
            style: TextStyle(fontSize: 12, color: C.primary, fontWeight: FontWeight.w600)),
      ),
      SecondaryButton(
        label: _recording
            ? 'Stop recording · ${_clock(_seconds)}'
            : 'Record a voice note',
        icon: _recording ? Icons.stop_circle_outlined : Icons.mic_none,
        onPressed: _toggleRecord,
      ),
      if (_recording)
        const InfoBox(
          icon: Icons.fiber_manual_record,
          tone: Tone.danger,
          title: 'Recording…',
          text: 'Speak when you are ready. Recording stops after 3 minutes.',
        ),
      for (var i = 0; i < items.length; i++)
        AppCard(
          bottom: 8,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(items[i].kind == 'voice' ? Icons.mic : Icons.insert_drive_file_outlined,
                color: C.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tx(items[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Tx(
                    items[i].kind == 'voice'
                        ? '${_clock(items[i].seconds ?? 0)} · ${_size(items[i].size)}'
                        : _size(items[i].size),
                    style: const TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: () => _removeAt(i),
              icon: const Icon(Icons.close),
            ),
          ]),
        ),
      const InfoBox(
        icon: Icons.visibility_off_outlined,
        title: 'Evidence can reveal your identity',
        text:
            'Photos can include hidden details like location and device. A voice can be recognized. Only attach what feels safe. Files are renamed before upload.',
      ),
    ]);
  }
}
