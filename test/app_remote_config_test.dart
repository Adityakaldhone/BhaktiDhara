import 'package:flutter_test/flutter_test.dart';
import 'package:nitya_aarti/domain/entities/app_remote_config.dart';

void main() {
  test('compares versions numerically and ignores build numbers', () {
    expect(AppRemoteConfig.compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(AppRemoteConfig.compareVersions('1.0.6+6', '1.0.6'), 0);
    expect(AppRemoteConfig.compareVersions('1.0', '1.0.1'), lessThan(0));
  });

  test('force update only applies below the minimum when enabled', () {
    const config = AppRemoteConfig(minSupportedVersion: '1.1.0', forceUpdate: true);
    expect(config.mustUpdate('1.0.6'), isTrue);
    expect(config.mustUpdate('1.1.0'), isFalse);
    expect(
      const AppRemoteConfig(minSupportedVersion: '1.1.0').mustUpdate('1.0.6'),
      isFalse,
    );
  });

  test('parses server JSON; unknown flags default to enabled', () {
    final config = AppRemoteConfig.fromJson({
      'latest_version': '1.0.7',
      'maintenance_mode': true,
      'maintenance_message': 'Back soon 🙏',
      'feature_flags': {'bhajan': false, 'ads': true},
    });
    expect(config.isEnabled(AppRemoteConfig.bhajan), isFalse);
    expect(config.isEnabled(AppRemoteConfig.ads), isTrue);
    expect(config.isEnabled(AppRemoteConfig.horoscope), isTrue);
    expect(config.maintenanceMode, isTrue);
    expect(config.canUpdate('1.0.6'), isTrue);
    expect(AppRemoteConfig.fromJson(config.toJson()).isEnabled('bhajan'), isFalse);
  });
}
