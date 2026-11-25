import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bhakti_wake_controller.dart';
import 'bhakti_voice_modal.dart';

class BhaktiWakeHost extends ConsumerStatefulWidget {
  const BhaktiWakeHost({
    super.key,
    required this.navigator,
    required this.child,
  });
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  ConsumerState<BhaktiWakeHost> createState() => _BhaktiWakeHostState();
}

class _BhaktiWakeHostState extends ConsumerState<BhaktiWakeHost>
    with WidgetsBindingObserver {
  late final BhaktiWakeController _wake;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wake = ref.read(bhaktiWakeProvider);
    _wake.onWake = () {
      final context = widget.navigator.currentState?.overlay?.context;
      if (mounted && context != null) {
        unawaited(BhaktiVoiceModal.show(context, ref, fromWake: true));
      }
    };
    _wake.foreground(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    unawaited(_wake.restore());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _wake.foreground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wake.onWake = null;
    _wake.foreground(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
