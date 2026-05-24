import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';

class HandsFreeCookingScreen extends StatefulWidget {
  final List<String> steps;
  final String title;

  const HandsFreeCookingScreen({
    super.key,
    required this.steps,
    required this.title,
  });

  @override
  State<HandsFreeCookingScreen> createState() => _HandsFreeCookingScreenState();
}

class _HandsFreeCookingScreenState extends State<HandsFreeCookingScreen> {
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;

  bool _isListening = false;
  int _currentStepIndex = 0;
  bool _speechEnabled = false;
  bool _localeInitialized = false;
  late bool _isTr;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      _isTr = Localizations.localeOf(context).languageCode == 'tr';
      _localeInitialized = true;
      _initTTS();
      _initSpeech();
    }
  }

  Future<void> _initTTS() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage(_isTr ? "tr-TR" : "en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    // İlk adımı oku
    _speakCurrentStep();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onStatus: (status) => debugPrint('STT Status: $status'),
      onError: (error) => debugPrint('STT Error: $error'),
    );
    if (_speechEnabled) {
      _startListening();
    }
    setState(() {});
  }

  Future<void> _speakCurrentStep() async {
    if (widget.steps.isEmpty) return;
    final String text = "${_isTr ? "Adım" : "Step"} ${_currentStepIndex + 1}: ${widget.steps[_currentStepIndex]}";
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    await _speech.listen(
      onResult: (result) {
        final String words = result.recognizedWords.toLowerCase();
        final isNext = _isTr
            ? (words.contains("ileri") || words.contains("devam") || words.contains("sonraki"))
            : (words.contains("next") || words.contains("continue") || words.contains("forward"));
        final isPrev = _isTr
            ? (words.contains("geri") || words.contains("önceki"))
            : (words.contains("back") || words.contains("previous"));

        if (isNext) {
          _speech.stop();
          _nextStep();
        } else if (isPrev) {
          _speech.stop();
          _previousStep();
        }
      },
      localeId: _isTr ? "tr-TR" : "en-US",
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    setState(() {
      _isListening = true;
    });
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _speakCurrentStep();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_speech.isListening) {
          _startListening();
        }
      });
    } else {
      _flutterTts.speak(_isTr ? "Tarifin sonuna geldiniz. Afiyet olsun!" : "You have reached the end of the recipe. Bon appétit!");
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _speakCurrentStep();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_speech.isListening) {
          _startListening();
        }
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(_isTr ? "Bu tarif için adım bulunamadı." : "No steps found for this recipe.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_isTr ? 'Eller Serbest Modu' : 'Hands-Free Cooking', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // Adım Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _isTr ? 'ADIM ${_currentStepIndex + 1}/${widget.steps.length}' : 'STEP ${_currentStepIndex + 1}/${widget.steps.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.steps[_currentStepIndex],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(key: ValueKey(_currentStepIndex)).fadeIn(duration: 500.ms).slideY(),
                  ],
                ),
              ),
              const Spacer(),
              
              // İlerle / Geri Butonları (Manuel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 40,
                    color: AppColors.onSurfaceVariant,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: _previousStep,
                  ),
                  
                  // Dinleme Mikrofon Göstergesi
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : AppColors.primary,
                        boxShadow: [
                          if (_isListening)
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms, curve: Curves.easeInOut),
                  
                  IconButton(
                    iconSize: 40,
                    color: AppColors.onSurfaceVariant,
                    icon: const Icon(Icons.skip_next),
                    onPressed: _nextStep,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text(
                _isListening 
                    ? (_isTr ? '"İleri" veya "Geri" diyerek komut verin' : 'Say "Next" or "Back" to give commands')
                    : (_isTr ? 'Dinleme duraklatıldı. Mikrofona dokunun.' : 'Listening paused. Tap the microphone.'),
                style: TextStyle(
                  color: _isListening ? Colors.red : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
