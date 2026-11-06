import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/parser/dictation.dart';

class DictationService {
  static final DictationService instance = DictationService._();
  DictationService._();

  Process? _recorder;
  Timer? _streamingTimer;
  bool _isListening = false;
  bool _isTranscribing = false;
  bool _isStreamInFlight = false;

  static const String _audioPath = '/tmp/tracetask_speech.wav';
  static const String _chunkPath = '/tmp/tracetask_chunk.wav';

  bool get isListening => _isListening;
  bool get isTranscribing => _isTranscribing;
  bool get isActive => _isListening || _isTranscribing;

  String? getApiKey() {
    final envKey = Platform.environment['GROQ_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;

    try {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
      if (home.isNotEmpty) {
        final configEnv = File('$home/.config/tracetask/.env');
        if (configEnv.existsSync()) {
          final lines = configEnv.readAsLinesSync();
          for (final line in lines) {
            if (line.startsWith('GROQ_API_KEY=')) {
              final key = line.substring('GROQ_API_KEY='.length).trim();
              if (key.isNotEmpty) return key;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onReady,
    void Function(String error)? onError,
  }) async {
    _streamingTimer?.cancel();
    _streamingTimer = null;

    if (_recorder != null || _isListening || _isTranscribing) {
      await stop(onResult: (text, isFinal) {});
    }

    if (!Platform.isLinux) {
      onError?.call('Voice dictation is currently supported on Linux desktop.');
      return false;
    }

    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      onError?.call('Set GROQ_API_KEY environment variable or in ~/.config/tracetask/.env');
      return false;
    }

    try {
      final file = File(_audioPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }

      // Check if pw-record exists (PipeWire)
      bool hasPwRecord = false;
      try {
        final whichResult = await Process.run('which', ['pw-record']);
        hasPwRecord = whichResult.exitCode == 0;
      } catch (_) {}

      if (hasPwRecord) {
        _recorder = await Process.start('pw-record', [
          '--rate',
          '16000',
          '--channels',
          '1',
          _audioPath,
        ]);
      } else {
        _recorder = await Process.start('arecord', [
          '-q',
          '-f',
          'S16_LE',
          '-r',
          '16000',
          '-c',
          '1',
          _audioPath,
        ]);
      }

      _isListening = true;
      _isTranscribing = false;
      _isStreamInFlight = false;
      onReady?.call();

      // Start periodic streaming transcription: updates text LIVE while speaking!
      _streamingTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
        if (!_isListening || _recorder == null) {
          timer.cancel();
          return;
        }

        if (_isStreamInFlight) return;

        final audioFile = File(_audioPath);
        if (!audioFile.existsSync() || audioFile.lengthSync() < 8000) {
          return;
        }

        _isStreamInFlight = true;
        try {
          // Extract valid WAV snapshot with complete header
          final fix = await Process.run('ffmpeg', [
            '-y',
            '-i',
            _audioPath,
            '-acodec',
            'copy',
            _chunkPath,
          ]);

          if (fix.exitCode == 0 && File(_chunkPath).existsSync()) {
            final transcribed = await _transcribeFile(_chunkPath);
            if (transcribed != null && transcribed.isNotEmpty && _isListening) {
              onResult(transcribed, false);
            }
          }
        } catch (_) {} finally {
          _isStreamInFlight = false;
        }
      });

      return true;
    } catch (e) {
      _reset();
      onError?.call('Microphone error: $e');
      return false;
    }
  }

  Future<void> stop({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onTranscribing,
    void Function(String error)? onError,
  }) async {
    _streamingTimer?.cancel();
    _streamingTimer = null;

    if (!_isListening && _recorder == null) {
      _reset();
      return;
    }

    _isListening = false;
    _isTranscribing = true;
    onTranscribing?.call();

    try {
      // Send SIGINT so pw-record finalizes the WAV file header cleanly
      if (_recorder != null) {
        _recorder?.kill(ProcessSignal.sigint);
        await _recorder?.exitCode.timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {
            _recorder?.kill(ProcessSignal.sigkill);
            return 0;
          },
        );
      }
    } catch (_) {}

    _recorder = null;

    final audioFile = File(_audioPath);
    if (!audioFile.existsSync() || audioFile.lengthSync() < 500) {
      _reset();
      onError?.call('No audio captured. Please speak clearly into the microphone.');
      return;
    }

    try {
      final transcribed = await _transcribeFile(_audioPath);
      _reset();
      if (transcribed != null) {
        onResult(transcribed, true);
      } else {
        onError?.call('Transcription failed. Check internet connection.');
      }
    } catch (e) {
      _reset();
      onError?.call('Dictation error: $e');
    }
  }

  Future<String?> _transcribeFile(String path) async {
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final result = await Process.run('curl', [
      '-s',
      'https://api.groq.com/openai/v1/audio/transcriptions',
      '-H',
      'Authorization: Bearer $apiKey',
      '-H',
      'Content-Type: multipart/form-data',
      '-F',
      'file=@$path',
      '-F',
      'model=whisper-large-v3-turbo',
      '-F',
      'temperature=0',
      '-F',
      'language=en',
    ]);

    if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
      try {
        final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
        if (json.containsKey('text')) {
          final rawText = (json['text'] as String).trim();
          if (rawText.isEmpty ||
              rawText == '.' ||
              rawText == 'Thank you.' ||
              rawText == 'Thank you' ||
              rawText == 'You') {
            return '';
          }
          return Dictation.normalize(rawText);
        }
      } catch (_) {}
    }
    return null;
  }

  void cancel() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    try {
      _recorder?.kill(ProcessSignal.sigkill);
    } catch (_) {}
    _reset();
  }

  void _reset() {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _recorder = null;
    _isListening = false;
    _isTranscribing = false;
    _isStreamInFlight = false;
  }
}
