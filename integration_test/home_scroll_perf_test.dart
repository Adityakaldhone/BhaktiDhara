import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nitya_aarti/main.dart' as app;

Map<String, dynamic> _summarise(List<FrameTiming> t) {
  double p(List<double> v, double q) {
    if (v.isEmpty) return 0;
    v.sort();
    return v[((v.length - 1) * q).round()];
  }

  final build = t.map((e) => e.buildDuration.inMicroseconds / 1000).toList();
  final raster =
      t.map((e) => e.rasterDuration.inMicroseconds / 1000).toList();
  final total =
      t.map((e) => e.totalSpan.inMicroseconds / 1000).toList();
  return {
    'frames': t.length,
    'build_avg': build.isEmpty ? 0 : build.reduce((a, b) => a + b) / build.length,
    'build_p90': p([...build], 0.9),
    'build_max': p([...build], 1),
    'raster_avg':
        raster.isEmpty ? 0 : raster.reduce((a, b) => a + b) / raster.length,
    'raster_p90': p([...raster], 0.9),
    'raster_max': p([...raster], 1),
    'jank_over_16ms': total.where((x) => x > 16.7).length,
    'jank_over_33ms': total.where((x) => x > 33.4).length,
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('home sacred collection scroll', (tester) async {
    app.main();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(CustomScrollView).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 2));
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('English').first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Continue'));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.byType(CustomScrollView).evaluate().isNotEmpty) break;
      }
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byIcon(Icons.close_rounded).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close_rounded).first);
        await tester.pump(const Duration(seconds: 1));
        break;
      }
    }
    await tester.pump(const Duration(seconds: 2));
    debugPrint('PERF_DEBUG csv=${find.byType(CustomScrollView, skipOffstage: false).evaluate().length} '
        'scaffolds=${find.byType(Scaffold, skipOffstage: false).evaluate().length} '
        'texts=${find.byType(Text).evaluate().take(15).map((e) => (e.widget as Text).data).toList()}');
    final list = find.byType(CustomScrollView, skipOffstage: false).first;
    final scrollable = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    double offset() =>
        tester.state<ScrollableState>(scrollable).position.pixels;
    final rect = tester.getRect(list);
    final hit = tester.hitTestOnBinding(rect.center);
    debugPrint('PERF_HIT rect=$rect path=${hit.path.take(6).map((e) => e.target.runtimeType).toList()}');
    final from = Offset(rect.center.dx, rect.top + rect.height * 0.6);

    final timings = <FrameTiming>[];
    void cb(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(cb);

    final phases = <String, Map<String, dynamic>>{};
    Future<void> phase(String name, Future<void> Function() body) async {
      final start = timings.length;
      await body();
      await tester.pump(const Duration(seconds: 1));
      phases[name] = _summarise(timings.sublist(start));
    }

    Future<void> down() async {
      for (var i = 0; i < 6; i++) {
        await tester.flingFrom(from, const Offset(0, -900), 2500);
        await tester.pump(const Duration(milliseconds: 1200));
      }
      debugPrint('PERF_OFFSET down ${offset()}');
    }

    Future<void> up() async {
      for (var i = 0; i < 6; i++) {
        await tester.flingFrom(from, const Offset(0, 900), 2500);
        await tester.pump(const Duration(milliseconds: 1200));
      }
      debugPrint('PERF_OFFSET up ${offset()}');
    }

    await phase('first_down', down);
    await phase('first_up', up);
    await phase('second_down', down);
    await phase('second_up', up);
    SchedulerBinding.instance.removeTimingsCallback(cb);

    phases['all'] = _summarise(timings);
    final worst = [...timings]
      ..sort((a, b) => b.totalSpan.compareTo(a.totalSpan));
    debugPrint('PERF_WORST ${worst.take(8).map((t) => 'b${t.buildDuration.inMicroseconds} r${t.rasterDuration.inMicroseconds}').toList()}');
    phases.forEach((k, v) => debugPrint('PERF_RESULT $k $v'));
    binding.reportData = phases;
  });
}
