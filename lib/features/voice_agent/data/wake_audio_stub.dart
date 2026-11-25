class WakeAudio {
  static const supported = false;
  Future<bool> permission({required bool request}) async => false;
  Future<void> start(void Function() wake, void Function() interrupted) async {}
  Future<void> stop() async {}
}
