import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../presentation/providers/bhakti_darshan_providers.dart';
import '../../../../presentation/providers/locale_provider.dart';
import '../../../../domain/entities/app_remote_config.dart';
import '../../../../presentation/providers/remote_config_provider.dart';
import '../../../../presentation/providers/jaap_providers.dart';
import '../../data/bhakti_speech.dart';
import '../../data/bhakti_wake_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/voice_agent_service.dart';
import '../../domain/voice_action_dispatcher.dart';
import '../../domain/home_voice_commands.dart';

enum VoiceOrbState { greeting, listening, processing, speaking, idle }

class BhaktiVoiceModal extends ConsumerStatefulWidget {
  const BhaktiVoiceModal({
    super.key,
    this.fromWake = false,
    this.homeHandler,
    this.homeScreen = false,
    this.onHomeAction,
  });
  final bool homeScreen;
  final HomeVoiceHandler? homeHandler;
  final ValueChanged<VoidCallback>? onHomeAction;
  final bool fromWake;
  static bool _showing = false;
  static VoidCallback? _wakeIdleSheet;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    bool fromWake = false,
  }) async {
    if (_showing) {
      if (fromWake) _wakeIdleSheet?.call();
      return;
    }
    _showing = true;
    final homeHandler = ref
        .read(homeVoiceBindingProvider)
        .activeHandler
        ?.call();
    final homeScreen =
        homeHandler != null &&
        homeHandler == ref.read(homeVoiceBindingProvider).homeHandler;
    VoidCallback? homeAction;
    final wake = ref.read(bhaktiWakeProvider);
    VoiceAgentResult? result;
    TransitionRoute<dynamic>? sheet;
    try {
      await wake.setModal(true);
      if (!context.mounted ||
          (fromWake &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed)) {
        return;
      }
      result = await showModalBottomSheet<VoiceAgentResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          sheet = ModalRoute.of(context);
          return BhaktiVoiceModal(
            fromWake: fromWake,
            homeHandler: homeHandler,
            homeScreen: homeScreen,
            onHomeAction: (action) => homeAction = action,
          );
        },
      );
      await sheet?.completed;
    } finally {
      _showing = false;
      await wake.setModal(false);
    }
    if (!context.mounted) return;
    if (homeAction != null) {
      homeAction!.call();
      return;
    }
    if (result == null) return;
    await VoiceActionDispatcher.execute(
      context: context,
      ref: ref,
      action: result.action,
      transcript: result.transcript,
    );
  }

  @override
  ConsumerState<BhaktiVoiceModal> createState() => _BhaktiVoiceModalState();
}

class _BhaktiVoiceModalState extends ConsumerState<BhaktiVoiceModal>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotationController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  VoiceOrbState _state = VoiceOrbState.greeting;
  String _activeMessage = '';
  String _recognizedTranscript = '';
  String? _pendingAction;
  Map<String, String>? _birthDetails;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    BhaktiVoiceModal._wakeIdleSheet = () {
      if (mounted &&
          _state == VoiceOrbState.idle &&
          ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_startListening());
      }
    };
    _initAndStartFlow();
  }

  @override
  void dispose() {
    BhaktiVoiceModal._wakeIdleSheet = null;
    _pulseController.dispose();
    _rotationController.dispose();
    _audioPlayer.dispose();
    unawaited(BhaktiSpeech.stop());
    _speechToText.statusListener = null;
    _speechToText.errorListener = null;
    unawaited(_speechToText.cancel());
    super.dispose();
  }

  Future<void> _initAndStartFlow() async {
    try {
      void onIdle() {
        if (mounted && _state == VoiceOrbState.listening) {
          _idle(message: "");
        }
      }

      void onStatus(String status) {
        if (status == stt.SpeechToText.doneStatus) onIdle();
      }

      // initialize() retains the first callbacks on this platform singleton.
      final available = await _speechToText.initialize(
        onStatus: onStatus,
        onError: (_) => onIdle(),
      );
      if (!mounted) return;
      _speechToText.statusListener = onStatus;
      _speechToText.errorListener = (_) => onIdle();
      if (!available) {
        _showSpeechUnavailable();
        return;
      }
    } catch (_) {
      _showSpeechUnavailable();
      return;
    }

    if (!mounted || _state != VoiceOrbState.greeting) return;
    if (widget.fromWake) {
      await _startListening();
      return;
    }
    final langCode = ref.read(localeProvider).languageCode;
    String greetingSound;
    String greetingText;

    if (langCode == 'hi') {
      greetingSound = 'sounds/bhakti_greeting_hi.mp3';
      greetingText =
          'नमस्ते, मैं भक्ति आपकी AI सहायक हूँ। आज मैं आपकी क्या सहायता कर सकती हूँ?';
    } else if (langCode == 'en') {
      greetingSound = 'sounds/bhakti_greeting_en.mp3';
      greetingText =
          'Namaste! I am Bhakti, your AI assistant. How can I help you today?';
    } else {
      greetingSound = 'sounds/bhakti_greeting_mr.mp3';
      greetingText =
          'नमस्कार, मी भक्ती आपली AI सहाय्यक आहे. आज मी आपली काय सेवा करू शकते?';
    }

    setState(() {
      _activeMessage = greetingText;
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _state == VoiceOrbState.greeting) {
        _startListening();
      }
    });

    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(greetingSound));
    } catch (_) {
      // If audio file playback fails on device, fallback directly to listening
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _state == VoiceOrbState.greeting) {
          _startListening();
        }
      });
    }
  }

  void _idle({String? message}) {
    if (!mounted) return;
    setState(() {
      _state = VoiceOrbState.idle;
      if (message != null) _activeMessage = message;
    });
    unawaited(ref.read(bhaktiWakeProvider).setModal(false));
  }

  void _showSpeechUnavailable() {
    if (mounted) {
      _idle(message: AppLocalizations.of(context)!.speechNotAvailable);
    }
  }

  Future<void> _startListening({String? prompt}) async {
    if (!mounted || _state == VoiceOrbState.listening) return;
    // Reserve the mic before an idle sheet can get a second wake callback.
    setState(() => _state = VoiceOrbState.listening);
    await ref.read(bhaktiWakeProvider).setModal(true);
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    HapticFeedback.lightImpact();

    final langCode = ref.read(localeProvider).languageCode;
    String targetLocaleId = 'mr_IN';
    if (langCode == 'hi') targetLocaleId = 'hi_IN';
    if (langCode == 'en') targetLocaleId = 'en_IN';

    setState(() {
      _state = VoiceOrbState.listening;
      _activeMessage =
          prompt ??
          (langCode == 'hi'
              ? 'सुन रही हूँ... (कुछ भी पूछें)'
              : (langCode == 'en'
                    ? 'Listening... (ask anything)'
                    : 'ऐकत आहे... (काहीही विचारा)'));
      _recognizedTranscript = '';
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedTranscript = result.recognizedWords;
          });

          if (result.finalResult && _recognizedTranscript.trim().isNotEmpty) {
            _handleFinalUserQuery(_recognizedTranscript.trim());
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: targetLocaleId,
          listenMode: stt.ListenMode.search,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (_) {
      if (mounted) _idle();
    }
  }

  Future<void> _handleFinalUserQuery(String query) async {
    if (!mounted || _state != VoiceOrbState.listening) return;

    setState(() {
      _state = VoiceOrbState.processing;
      _activeMessage = 'विचार करत आहे...';
    });
    await _speechToText.stop();
    if (!mounted) return;

    final langCode = ref.read(localeProvider).languageCode;
    final localeHint = langCode == 'hi'
        ? 'hi-IN'
        : (langCode == 'en' ? 'en-IN' : 'mr-IN');

    var homeReply = _pendingAction == null
        ? widget.homeHandler?.call(query, langCode)
        : null;
    if (homeReply == null && _pendingAction == null && widget.homeScreen) {
      final predicted = await VoiceAgentService.predictHomeCommand(
        query,
        localeHint,
      );
      if (!mounted) return;
      if (predicted != null)
        homeReply = widget.homeHandler?.call(
          query,
          langCode,
          prediction: predicted,
        );
    }
    final reply = homeReply;
    if (reply != null) {
      setState(() {
        _state = VoiceOrbState.speaking;
        _activeMessage = reply.text;
      });
      try {
        await BhaktiSpeech.speak(reply.text, localeHint: localeHint);
      } catch (_) {}
      if (!mounted) return;
      if (reply.apply case final apply?) {
        widget.onHomeAction?.call(apply);
        Navigator.of(context).pop();
      } else {
        _idle(message: reply.text);
      }
      return;
    }

    final resolved = await VoiceAgentService.processVoiceCommand(
      query,
      localeHint: localeHint,
      pendingAction: _pendingAction,
      birthDetails: _birthDetails,
      loadCatalog: () async => ref.read(bhaktiContentProvider),
      loadJaapProgress: () async {
        final current = ref.read(jaapProvider);
        return current.loaded
            ? current.progress
            : await ref.read(jaapRepositoryProvider).load();
      },
    );

    if (!mounted) return;

    if (resolved == null) {
      _idle(message: 'माफ करा, संपर्क होऊ शकला नाही.');
      return;
    }

    final result =
        resolved.action.type == 'open_premium' &&
            !ref.read(featureEnabledProvider(AppRemoteConfig.premiumPaywall))
        ? VoiceAgentService.notFound(query, localeHint)
        : resolved;
    _birthDetails = result.birthDetails;
    _pendingAction = result.status == 'needs_clarification'
        ? result.action.type
        : null;
    setState(() {
      _state = VoiceOrbState.speaking;
      _activeMessage = result.responseText;
    });

    try {
      await BhaktiSpeech.speak(result.responseText, localeHint: localeHint);
    } catch (_) {}

    if (!mounted) return;
    if (_pendingAction != null) {
      await _startListening(prompt: result.responseText);
      return;
    }
    if (result.action.type == 'none' ||
        result.action.type == 'answer_app_question') {
      _idle();
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    String localized(String en, String hi, String mr) => lang == 'en'
        ? en
        : lang == 'hi'
        ? hi
        : mr;
    final caption = switch (_state) {
      VoiceOrbState.listening => localized(
        'Listening',
        'सुन रही हूँ',
        'ऐकत आहे',
      ),
      VoiceOrbState.processing => localized(
        'Finding your answer',
        'जवाब ढूँढ रही हूँ',
        'उत्तर शोधत आहे',
      ),
      VoiceOrbState.idle => localized('Ready', 'तैयार हूँ', 'तयार आहे'),
      _ => localized(
        'Bhakti is speaking',
        'भक्ति बोल रही है',
        'भक्ती बोलत आहे',
      ),
    };
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF140905), // Deep Sacred Temple Night
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF9900),
            blurRadius: 40,
            spreadRadius: -10,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    // Modal Top Handle
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF9900,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFF9900,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'भक्ती AI',
                                style: GoogleFonts.mukta(
                                  color: const Color(0xFFFFB74D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voice Assistant',
                              style: GoogleFonts.mukta(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Fluid Meta AI / ChatGPT Voice Orb
                    GestureDetector(
                      onTap: () {
                        if (_state == VoiceOrbState.greeting ||
                            _state == VoiceOrbState.idle) {
                          _audioPlayer.stop();
                          _startListening(
                            prompt: _pendingAction == null
                                ? null
                                : _activeMessage,
                          );
                        }
                      },
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _pulseController,
                          _rotationController,
                        ]),
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          final angle = _rotationController.value * 2 * math.pi;

                          // Dynamic sizing based on voice state
                          final orbScale =
                              _state == VoiceOrbState.speaking ||
                                  _state == VoiceOrbState.greeting
                              ? 1.0 + (pulse * 0.15)
                              : (_state == VoiceOrbState.listening
                                    ? 1.0 + (pulse * 0.22)
                                    : 1.0);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Pulsing Ripple Rings
                              Container(
                                width: 170 * orbScale,
                                height: 170 * orbScale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFFFF9900,
                                  ).withValues(alpha: 0.08 * (1.0 - pulse)),
                                ),
                              ),
                              Container(
                                width: 145 * orbScale,
                                height: 145 * orbScale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFFE040FB,
                                  ).withValues(alpha: 0.12 * (1.0 - pulse)),
                                ),
                              ),
                              // Rotating Fluid Meta AI Gradient Ring
                              Transform.rotate(
                                angle: angle,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Color(0xFFFF9900), // Devotional Saffron
                                        Color(0xFFE040FB), // Magenta Purple
                                        Color(0xFF00E5FF), // Cyan
                                        Color(0xFFFFD700), // Sun Gold
                                        Color(0xFFFF9900), // Saffron
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Inner Dark Glass Sphere Center
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFF4A1F12),
                                      Color(0xFF1B0B05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF9900,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    _state == VoiceOrbState.listening
                                        ? Icons.mic
                                        : (_state == VoiceOrbState.processing
                                              ? Icons.hourglass_top_rounded
                                              : Icons.auto_awesome),
                                    color: const Color(0xFFFFE082),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Status Caption
                    Text(
                      caption,
                      style: GoogleFonts.mukta(
                        color: const Color(0xFFFFB74D),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Active Spoken Message / Live Transcript
                    Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        _state == VoiceOrbState.listening &&
                                _recognizedTranscript.isNotEmpty
                            ? _recognizedTranscript
                            : _activeMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.mukta(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bottom hint
                    Text(
                      'टॅप करा आणि बोला: "कुंभ राशीचे भविष्य", "आजचा राहुकाळ", "सुखकर्ता आरती"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mukta(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
