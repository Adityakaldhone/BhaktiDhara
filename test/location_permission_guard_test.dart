import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nitya_aarti/services/app_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'requestLocationPermissionSafely deduplicates concurrent requests and maps responses',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const channel = MethodChannel('bhaktidhara/location_permission');
      final calls = <String>[];
      final completer = Completer<String>();

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return completer.future;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final f1 = AppPermissionService.requestLocationPermissionSafely();
      final f2 = AppPermissionService.requestLocationPermissionSafely();

      expect(calls, ['requestLocationPermission']);
      completer.complete('whileInUse');

      final results = await Future.wait([f1, f2]);
      expect(results, [
        LocationPermission.whileInUse,
        LocationPermission.whileInUse,
      ]);
    },
  );
}
