import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/app_remote_config.dart';
import 'package:nitya_aarti/presentation/providers/remote_config_provider.dart';
import 'package:nitya_aarti/presentation/screens/force_update_screen.dart';
import 'package:nitya_aarti/presentation/widgets/remote_notices.dart';

void main() {
  testWidgets('renders child normally when update is not required', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteConfigProvider.overrideWith(
            (ref) => _StaticRemoteConfigNotifier(
              const AppRemoteConfig(minSupportedVersion: '1.0.0', forceUpdate: false),
            ),
          ),
          appVersionProvider.overrideWith((ref) => Future.value('1.0.7')),
        ],
        child: const MaterialApp(
          home: ForceUpdateGate(
            child: Text('Normal Dashboard Content'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Normal Dashboard Content'), findsOneWidget);
    expect(find.byType(ForceUpdateScreen), findsNothing);
  });

  testWidgets('renders ForceUpdateScreen and blocks child when mustUpdate is true',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteConfigProvider.overrideWith(
            (ref) => _StaticRemoteConfigNotifier(
              const AppRemoteConfig(
                minSupportedVersion: '2.0.0',
                latestVersion: '2.0.0',
                forceUpdate: true,
              ),
            ),
          ),
          appVersionProvider.overrideWith((ref) => Future.value('1.0.7')),
        ],
        child: const MaterialApp(
          home: ForceUpdateGate(
            child: Text('Normal Dashboard Content'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Normal Dashboard Content'), findsNothing);
    expect(find.byType(ForceUpdateScreen), findsOneWidget);
    expect(find.text('v1.0.7'), findsOneWidget);
    expect(find.text('v2.0.0+'), findsOneWidget);
  });
}

class _StaticRemoteConfigNotifier extends RemoteConfigNotifier {
  _StaticRemoteConfigNotifier(AppRemoteConfig initial) {
    state = initial;
  }

  @override
  Future<void> refresh() async {}
}
