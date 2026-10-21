import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ClarityService {
  static void setUserId(String userId) {
    Clarity.setCustomUserId(userId);
  }

  static Widget wrapWithClarity({required Widget child, required String projectId}) {
    return ClarityWidget(
      clarityConfig: ClarityConfig(
        projectId: projectId,
        logLevel: kDebugMode ? LogLevel.Info : LogLevel.None,
      ),
      app: child,
    );
  }
}
