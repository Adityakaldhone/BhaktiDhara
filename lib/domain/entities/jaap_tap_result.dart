enum JaapTapOutcome { bead, malaComplete, goalComplete }

class JaapTapResult {
  final JaapTapOutcome outcome;

  /// Lifetime milestone crossed by this tap, if any.
  final int? milestone;

  const JaapTapResult(this.outcome, {this.milestone});
}
