import 'package:flutter/widgets.dart';

class ClarityService {
  static void setUserId(String userId) {
    // No-op on Web (or use Microsoft Clarity JS snippet)
  }

  static Widget wrapWithClarity({required Widget child, required String projectId}) {
    return child;
  }
}
